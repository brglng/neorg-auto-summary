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
            }
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
                if filename ~= summary_name then
                    module.public.auto_summary()
                end
            end
        })
    end
end

module.config.public = {
    name = "index.norg",
    autocmd = false,
}

---@class external.auto-summary
module.public = {
    auto_summary = function()
        local dirman = modules.get_module("core.dirman")
        local ts = module.required["core.integrations.treesitter"]

        if not dirman then
            utils.notify("`core.dirman` is not loaded! It is required to generate summaries")
            return
        end

        local ws_root = dirman.get_current_workspace()[2]
        local summary_path = vim.fs.normalize(vim.fs.abspath(vim.fn.resolve(ws_root .. "/" .. module.config.public.name)))

        local generated = vim.list_extend(
            { "* Index" },
            module.private.generate_summary_lines(
                dirman.get_norg_files(dirman.get_current_workspace()[1]) or {},
                ws_root,
                summary_path
            )
        )

        local buf = nil
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
            local buf_path = vim.fs.normalize(vim.fs.abspath(vim.fn.resolve(vim.api.nvim_buf_get_name(b))))
            if buf_path == summary_path then
                buf = b
                break
            end
        end

        if not buf then
            buf = vim.api.nvim_create_buf(true, false)
            vim.api.nvim_buf_call(buf, function()
                vim.cmd("edit " .. summary_path)
                vim.cmd("set filetype=norg")
            end)
        end

        local metadata = nil ---@type string[]?

        local query = utils.ts_parse_query(
            "norg",
            [[
                (ranged_verbatim_tag
                    (tag_name) @name
                    (#eq? @name "document.meta")
                ) @meta
            ]]
        )

        local root = ts.get_document_root(buf)

        if root then
            local _, found = query:iter_matches(root, buf)()
            if found then
                for id, node in pairs(found) do
                    local name = query.captures[id]
                    -- node is a list in nvim 0.11+
                    if vim.islist(node) then
                        node = node[1]
                    end
                    if name == "meta" then
                        local start_row, _, start_col, end_row, _, end_col = node:range(true)
                        metadata = vim.api.nvim_buf_get_text(buf, start_row, start_col, end_row, end_col, {})
                        break
                    end
                end
            end
        end

        if metadata then
            metadata = vim.list_extend(metadata, {""})
            generated = vim.list_extend(metadata, generated)
        end

        vim.api.nvim_buf_set_lines(buf, 0, -1, false, generated)

        vim.schedule(function()
            vim.api.nvim_buf_call(buf, function()
                vim.cmd("update")
            end)
            utils.notify("Summary generated at " .. summary_path)
        end)
    end,
}

module.private = {
    -- Parse metadata from a .norg file without loading it as a buffer.
    -- Returns a table with keys like `title`, `description`, `categories` (list).
    -- Category names are returned as-is (no case normalization).
    parse_norg_metadata = function(filepath)
        local f = io.open(filepath, "r")
        if not f then
            return {}
        end
        local content = f:read("*all")
        f:close()

        local meta_content = content:match("@document%.meta%s*\n(.-)\n@end")
        if not meta_content then
            return {}
        end

        local metadata = {}
        local in_categories = false
        local categories = {}

        for _, line in ipairs(vim.split(meta_content, "\n", { plain = true })) do
            if in_categories then
                if line:match("^%s*%]%s*$") then
                    in_categories = false
                    metadata.categories = categories
                else
                    local cat = line:match("^%s*(.-)%s*$")
                    if cat ~= "" then
                        table.insert(categories, cat)
                    end
                end
            else
                -- Inline array: categories: [cat1 cat2]
                local inline = line:match("^%s*categories%s*:%s*%[(.-)%]%s*$")
                if inline then
                    metadata.categories = {}
                    for cat in inline:gmatch("%S+") do
                        table.insert(metadata.categories, cat)
                    end
                -- Opening of multiline array: categories: [
                elseif line:match("^%s*categories%s*:%s*%[%s*$") then
                    in_categories = true
                    categories = {}
                else
                    local key, value = line:match("^%s*(%w+)%s*:%s*(.+)$")
                    if key then
                        metadata[key] = value:match("^%s*(.-)%s*$")
                    end
                end
            end
        end

        return metadata
    end,

    -- Generate summary lines for a list of norg files.
    -- Files are grouped by category without any case normalization.
    -- List items start at column 0 (aligned with the `**` heading marker).
    generate_summary_lines = function(files, ws_root, summary_path)
        local ws_norm = vim.fs.normalize(tostring(ws_root))
        local categorized = {}
        local category_order = {}

        for _, file in ipairs(files) do
            local abs_path = vim.fs.normalize(tostring(file))

            -- Skip the summary file itself
            if abs_path == summary_path then
                goto continue
            end

            local metadata = module.private.parse_norg_metadata(abs_path)

            -- Path relative to workspace root, without .norg extension, used in links.
            -- The leading "/" is intentional: combined with the "$" workspace anchor it
            -- produces links of the form {:$/path/to/file:}[Title].
            local norgname = abs_path:gsub("^" .. vim.pesc(ws_norm), ""):gsub("%.norg$", "")

            -- Fall back to filename when no title is present in metadata
            local title = (metadata.title and metadata.title ~= "") and metadata.title
                or vim.fs.basename(abs_path):gsub("%.norg$", "")

            local description = metadata.description

            local cats = metadata.categories
            if not cats or #cats == 0 then
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

        local result = {}

        for _, category in ipairs(category_order) do
            table.insert(result, "** " .. category)
            for _, entry in ipairs(categorized[category]) do
                local line = "- {:$" .. entry.norgname .. ":}[" .. entry.title .. "]"
                if entry.description and entry.description ~= "" then
                    line = line .. " - " .. entry.description
                end
                table.insert(result, line)
            end
        end

        return result
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
    }
}

return module
