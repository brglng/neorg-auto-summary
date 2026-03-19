--[[
    file: module.lua
    title: Auto Summary Module for Neorg
    description: Automatically generate summaries for Neorg documents
    author: neorg-auto-summary
--]]

local neorg = require("neorg.core")
local modules, utils = neorg.modules, neorg.utils

local module = modules.create("external.auto-summary")

module.setup = function()
    return {
        success = true,
        requires = {
            "core.dirman",
            "core.esupports.metagen",
            "core.integrations.treesitter",
        },
    }
end

module.load = function()
    modules.await("core.neorgcmd", function(neorgcmd)
        neorgcmd.add_commands_from_table({
            ["auto-summary"] = {
                min_args = 0,
                name = "auto-summary.summarize",
            },
        })
    end)
    if module.config.public.autocmd then
        vim.api.nvim_create_autocmd("BufWritePost", {
            pattern = "*.norg",
            callback = function(e)
                local dirman = module.required["core.dirman"]
                local ws_root = dirman.get_current_workspace()[2]
                local filename = vim.fs.normalize(vim.fs.abspath(vim.fn.resolve(e.file)))
                local summary_name = vim.fs.normalize(vim.fn.resolve(ws_root .. "/" .. module.config.public.name))
                if filename == summary_name then
                    return
                end
                if module.config.public.sub_category_file then
                    local cats_dir =
                        vim.fs.normalize(vim.fn.resolve(ws_root .. "/" .. module.config.public.categories_dir))
                    if vim.startswith(filename, cats_dir .. "/") then
                        return
                    end
                end
                module.public.auto_summary()
            end,
        })
    end
end

module.config.public = {
    name = "index.norg",
    autocmd = false,
    category_separator = ".",
    sub_category_file = true,
    categories_dir = "categories",
    list_children_in_parent = true,
}

---@class external.auto-summary
module.public = {
    auto_summary = function()
        local dirman = modules.get_module("core.dirman")

        if not dirman then
            utils.notify("`core.dirman` is not loaded! It is required to generate summaries")
            return
        end

        local ws_root = dirman.get_current_workspace()[2]
        local ws_norm = vim.fs.normalize(tostring(ws_root))
        local config = module.config.public
        local summary_path = vim.fs.normalize(vim.fs.abspath(vim.fn.resolve(ws_norm .. "/" .. config.name)))

        local cats_dir_abs = nil
        if config.sub_category_file then
            cats_dir_abs = vim.fs.normalize(vim.fn.resolve(ws_norm .. "/" .. config.categories_dir))
        end

        -- Collect entries from all norg files
        local categorized, category_order = module.private.collect_entries(
            dirman.get_norg_files(dirman.get_current_workspace()[1]) or {},
            ws_norm,
            summary_path,
            cats_dir_abs
        )

        -- Build category tree
        local tree = module.private.build_category_tree(categorized, category_order, config.category_separator)

        if config.sub_category_file then
            -- Generate main summary with links to category files
            local main_lines = module.private.generate_main_summary_with_files(tree)

            -- Generate all category file contents (relative paths -> content)
            local category_files = module.private.generate_all_category_files(tree)

            -- Read existing metadata from main summary
            local main_metadata = module.private.read_existing_metadata(summary_path)

            -- Close buffers for main summary
            module.private.close_file_buffers(summary_path)

            -- Build main content
            local main_content = table.concat(main_lines, "\n") .. "\n"
            if main_metadata then
                main_content = table.concat(main_metadata, "\n") .. "\n\n" .. main_content
            end

            -- Clean up existing categories directory and recreate
            if cats_dir_abs and vim.fn.isdirectory(cats_dir_abs) == 1 then
                vim.fn.delete(cats_dir_abs, "rf")
            end

            -- Prepare all files for writing
            local files_to_write = {}
            table.insert(files_to_write, { path = summary_path, content = main_content })

            for rel_path, content in pairs(category_files) do
                local abs_path = vim.fs.normalize(ws_norm .. "/" .. rel_path)
                local dir = vim.fn.fnamemodify(abs_path, ":h")
                vim.fn.mkdir(dir, "p")
                table.insert(files_to_write, { path = abs_path, content = content })
            end

            -- Write all files asynchronously
            module.private.write_files_async(files_to_write, function()
                vim.schedule(function()
                    utils.notify("Summary generated at " .. summary_path)
                end)
            end)
        else
            -- Generate main summary with tree sub-headings
            local main_lines = vim.list_extend({ "* Index" }, module.private.generate_tree_lines(tree, 2))

            -- Read existing metadata
            local metadata = module.private.read_existing_metadata(summary_path)

            -- Close buffers
            module.private.close_file_buffers(summary_path)

            -- Build content
            local content = table.concat(main_lines, "\n") .. "\n"
            if metadata then
                content = table.concat(metadata, "\n") .. "\n\n" .. content
            end

            -- Write single file
            module.private.write_file_async(summary_path, content, function(err)
                vim.schedule(function()
                    if err then
                        utils.notify("Failed to write summary file: " .. err)
                    else
                        utils.notify("Summary generated at " .. summary_path)
                    end
                end)
            end)
        end
    end,
}

module.private = {
    --- Collect entries from norg files, grouped by category.
    --- @param files string[] list of absolute file paths
    --- @param ws_norm string normalized workspace root
    --- @param summary_path string absolute path of the main summary file to skip
    --- @param cats_dir_abs string|nil absolute path of the categories directory to skip
    --- @return table categorized map of full category string -> entries list
    --- @return string[] category_order ordered list of unique full category strings
    collect_entries = function(files, ws_norm, summary_path, cats_dir_abs)
        local ts = module.required["core.integrations.treesitter"]
        local categorized = {}
        local category_order = {}

        for _, file in ipairs(files) do
            local abs_path = vim.fs.normalize(tostring(file))

            -- Skip the summary file
            if abs_path == summary_path then
                goto continue
            end

            -- Skip files inside the categories directory
            if cats_dir_abs and vim.startswith(abs_path, cats_dir_abs .. "/") then
                goto continue
            end

            -- get_document_metadata requires a bufnr, so open a hidden buffer
            local bufnr = vim.fn.bufnr(abs_path)
            local created_buf = false
            if bufnr == -1 then
                bufnr = vim.fn.bufadd(abs_path)
                created_buf = true
            end
            if not vim.api.nvim_buf_is_loaded(bufnr) then
                vim.fn.bufload(bufnr)
            end

            local metadata = ts.get_document_metadata(bufnr) or {}

            if created_buf then
                vim.api.nvim_buf_delete(bufnr, { force = true })
            end

            -- Path relative to workspace root, without .norg extension, used in links.
            -- The leading "/" is intentional: combined with the "$" workspace anchor it
            -- produces links of the form {:$/path/to/file:}[Title].
            local norgname = abs_path:gsub("^" .. vim.pesc(ws_norm), ""):gsub("%.norg$", "")

            -- Fall back to filename when no title is present in metadata
            local title = (metadata.title ~= vim.NIL and metadata.title ~= "") and metadata.title
                or vim.fs.basename(abs_path):gsub("%.norg$", "")

            local description = (metadata.description ~= vim.NIL) and metadata.description

            local cats = metadata.categories
            if not cats or cats == vim.NIL then
                cats = { "Uncategorized" }
            elseif type(cats) ~= "table" then
                cats = { tostring(cats) }
            end

            local entry = { title = title, norgname = norgname, description = description }

            for _, cat in ipairs(cats) do
                if not categorized[cat] then
                    categorized[cat] = {}
                    table.insert(category_order, cat)
                end
                table.insert(categorized[cat], entry)
            end

            ::continue::
        end

        return categorized, category_order
    end,

    --- Build a category tree from flat categorized entries.
    --- Each node has: children (map), child_order (list), entries (list).
    --- @param categorized table map of full category string -> entries list
    --- @param category_order string[] ordered list of full category strings
    --- @param separator string the sub-category separator
    --- @return table tree root node
    build_category_tree = function(categorized, category_order, separator)
        local tree = { children = {}, entries = {}, child_order = {} }

        for _, full_cat in ipairs(category_order) do
            local parts = vim.split(full_cat, separator, { plain = true })
            -- Filter out empty parts from leading/trailing/double separators
            parts = vim.tbl_filter(function(p)
                return p ~= ""
            end, parts)
            if #parts == 0 then
                parts = { full_cat }
            end

            local node = tree
            for _, part in ipairs(parts) do
                if not node.children[part] then
                    node.children[part] = { children = {}, entries = {}, child_order = {} }
                    table.insert(node.child_order, part)
                end
                node = node.children[part]
            end

            for _, entry in ipairs(categorized[full_cat]) do
                table.insert(node.entries, entry)
            end
        end

        return tree
    end,

    --- Recursively collect all entries from a node and its descendants.
    collect_all_entries = function(node)
        local entries = {}
        for _, entry in ipairs(node.entries) do
            table.insert(entries, entry)
        end
        for _, child_name in ipairs(node.child_order) do
            vim.list_extend(entries, module.private.collect_all_entries(node.children[child_name]))
        end
        return entries
    end,

    --- Check if a tree node has any children.
    has_children = function(node)
        return #node.child_order > 0
    end,

    --- Get the relative file path (from workspace root) for a category node.
    --- Branch nodes: <categories_dir>/<path...>/<name>
    --- Leaf nodes:   <categories_dir>/<parent_path...>/<category_name>.norg
    get_category_rel_path = function(path_parts, node)
        local config = module.config.public
        if module.private.has_children(node) then
            local parts = { config.categories_dir }
            for _, p in ipairs(path_parts) do
                table.insert(parts, p)
            end
            table.insert(parts, config.name)
            return table.concat(parts, "/")
        else
            local parts = { config.categories_dir }
            for i = 1, #path_parts - 1 do
                table.insert(parts, path_parts[i])
            end
            table.insert(parts, path_parts[#path_parts] .. ".norg")
            return table.concat(parts, "/")
        end
    end,

    --- Get the norgname (for links) of a category file.
    --- Returns a path like /categories/a/b/index (without .norg).
    get_category_norgname = function(path_parts, node)
        local rel_path = module.private.get_category_rel_path(path_parts, node)
        return "/" .. rel_path:gsub("%.norg$", "")
    end,

    --- Format a list of entries as indented link lines.
    format_entry_lines = function(entries, indent)
        local lines = {}
        for _, entry in ipairs(entries) do
            local line = indent .. "- {:$" .. entry.norgname .. ":}[" .. entry.title .. "]"
            if entry.description and entry.description ~= "" then
                line = line .. " - " .. entry.description
            end
            table.insert(lines, line)
        end
        return lines
    end,

    --- Generate main summary lines when sub_category_file is enabled.
    --- Top-level categories become headings that link to their summary files.
    generate_main_summary_with_files = function(tree)
        local config = module.config.public
        local heading_level = 1
        local indent = string.rep(" ", heading_level + 1)
        local result = { string.rep("*", heading_level) .. " Index" }

        -- If list_children_in_parent, add all entries flattened under the top heading
        if config.list_children_in_parent then
            vim.list_extend(result, module.private.format_entry_lines(module.private.collect_all_entries(tree), indent))
        end

        -- Add top-level category headings with links
        local child_heading_level = 2
        for _, child_name in ipairs(tree.child_order) do
            local child = tree.children[child_name]
            local norgname = module.private.get_category_norgname({ child_name }, child)
            table.insert(
                result,
                string.rep("*", child_heading_level) .. " {:$" .. norgname .. ":}[" .. child_name .. "]"
            )
        end

        return result
    end,

    --- Generate tree lines for inline mode (sub_category_file is false).
    --- Sub-categories become nested headings with increasing heading levels.
    generate_tree_lines = function(node, heading_level)
        local result = {}
        for _, child_name in ipairs(node.child_order) do
            local child = node.children[child_name]
            local indent = string.rep(" ", heading_level + 1)

            table.insert(result, string.rep("*", heading_level) .. " " .. child_name)

            -- List direct entries under this heading
            vim.list_extend(result, module.private.format_entry_lines(child.entries, indent))

            -- Recurse into children
            if module.private.has_children(child) then
                vim.list_extend(result, module.private.generate_tree_lines(child, heading_level + 1))
            end
        end
        return result
    end,

    --- Generate all category file contents.
    --- @return table map of relative_path -> content_string
    generate_all_category_files = function(tree)
        local config = module.config.public
        local files = {}

        local function generate_node(node, node_name, path_parts)
            local rel_path = module.private.get_category_rel_path(path_parts, node)
            local heading_level = 1
            local indent = string.rep(" ", heading_level + 1)
            local lines = { string.rep("*", heading_level) .. " " .. node_name }

            if module.private.has_children(node) then
                -- Branch node
                if config.list_children_in_parent then
                    -- Add all descendant entries flattened
                    vim.list_extend(
                        lines,
                        module.private.format_entry_lines(module.private.collect_all_entries(node), indent)
                    )
                else
                    -- Add only direct entries
                    vim.list_extend(lines, module.private.format_entry_lines(node.entries, indent))
                end

                -- Add children headings with links
                local child_heading_level = 2
                for _, child_name in ipairs(node.child_order) do
                    local child = node.children[child_name]
                    local child_path_parts = vim.list_extend({}, path_parts)
                    table.insert(child_path_parts, child_name)
                    local norgname = module.private.get_category_norgname(child_path_parts, child)
                    table.insert(
                        lines,
                        string.rep("*", child_heading_level) .. " {:$" .. norgname .. ":}[" .. child_name .. "]"
                    )
                end
            else
                -- Leaf node: list direct entries
                vim.list_extend(lines, module.private.format_entry_lines(node.entries, indent))
            end

            files[rel_path] = table.concat(lines, "\n") .. "\n"

            -- Recurse into children
            for _, child_name in ipairs(node.child_order) do
                local child = node.children[child_name]
                local child_path_parts = vim.list_extend({}, path_parts)
                table.insert(child_path_parts, child_name)
                generate_node(child, child_name, child_path_parts)
            end
        end

        for _, child_name in ipairs(tree.child_order) do
            generate_node(tree.children[child_name], child_name, { child_name })
        end

        return files
    end,

    --- Read existing @document.meta from a file (if it exists).
    --- @return string[]|nil metadata lines or nil
    read_existing_metadata = function(path)
        local ts = module.required["core.integrations.treesitter"]

        if vim.fn.filereadable(path) ~= 1 then
            return nil
        end

        local bufnr = vim.fn.bufnr(path)
        local created_buf = false
        if bufnr == -1 then
            bufnr = vim.fn.bufadd(path)
            created_buf = true
        end
        if not vim.api.nvim_buf_is_loaded(bufnr) then
            vim.fn.bufload(bufnr)
        end

        local query = utils.ts_parse_query(
            "norg",
            [[
                (ranged_verbatim_tag
                    (tag_name) @name
                    (#eq? @name "document.meta")
                ) @meta
            ]]
        )

        local root = ts.get_document_root(bufnr)
        local metadata = nil

        if root then
            local _, found = query:iter_matches(root, bufnr)()
            if found then
                for id, node in pairs(found) do
                    local name = query.captures[id]
                    -- node is a list in nvim 0.11+
                    if vim.islist(node) then
                        node = node[1]
                    end
                    if name == "meta" then
                        local start_row, _, start_col, end_row, _, end_col = node:range(true)
                        metadata = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
                        break
                    end
                end
            end
        end

        if created_buf then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end

        return metadata
    end,

    --- Close all buffers associated with a file path.
    close_file_buffers = function(path)
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(b) then
                local buf_path = vim.fs.normalize(vim.fs.abspath(vim.fn.resolve(vim.api.nvim_buf_get_name(b))))
                if buf_path == path then
                    vim.api.nvim_buf_delete(b, { force = true })
                end
            end
        end
    end,

    --- Write a single file asynchronously.
    --- callback(err) is called on completion; err is nil on success.
    write_file_async = function(path, content, callback)
        -- 438 is octal 0666 (rw-rw-rw-), the standard permission for new files
        vim.uv.fs_open(path, "w", 438, function(open_err, fd)
            if open_err then
                callback("Failed to open " .. path .. ": " .. open_err)
                return
            end
            vim.uv.fs_write(fd, content, nil, function(write_err, _)
                vim.uv.fs_close(fd, function(close_err)
                    if write_err then
                        callback("Failed to write " .. path .. ": " .. write_err)
                    elseif close_err then
                        callback("Failed to close " .. path .. ": " .. close_err)
                    else
                        callback(nil)
                    end
                end)
            end)
        end)
    end,

    --- Write multiple files asynchronously, calling on_done when all complete.
    write_files_async = function(files, on_done)
        if #files == 0 then
            on_done()
            return
        end

        local completed = 0
        local errors = {}

        for _, file_info in ipairs(files) do
            module.private.write_file_async(file_info.path, file_info.content, function(err)
                if err then
                    table.insert(errors, err)
                end
                completed = completed + 1
                if completed == #files then
                    if #errors > 0 then
                        vim.schedule(function()
                            utils.notify("Errors writing files:\n" .. table.concat(errors, "\n"))
                        end)
                    else
                        on_done()
                    end
                end
            end)
        end
    end,
}

module.on_event = function(event)
    if event.type == "core.neorgcmd.events.auto-summary.summarize" then
        vim.schedule(function()
            module.public.auto_summary()
        end)
    end
end

module.events.subscribed = {
    ["core.neorgcmd"] = {
        ["auto-summary.summarize"] = true,
    },
}

return module
