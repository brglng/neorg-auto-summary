--[[
    file: module.lua
    title: Auto Summary Module for Neorg
    description: Automatically generate summaries for Neorg documents
    author: neorg-auto-summary
--]]

local neorg = require("neorg.core")
local lib, modules, utils = neorg.lib, neorg.modules, neorg.utils

local module = modules.create("external.auto-summary")

module.setup = function()
    return {
        success = true,
        requires = {
            "core.dirman",
            "core.esupports.metagen",
            "core.integrations.treesitter",
            "core.summary"
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
        local summary = module.required["core.summary"]
        local ts = module.required["core.integrations.treesitter"]

        if not dirman then
            utils.notify("`core.dirman` is not loaded! It is required to generate summaries")
            return
        end

        local ws_root = dirman.get_current_workspace()[2]
        local summary_path = vim.fs.normalize(vim.fs.abspath(vim.fn.resolve(ws_root .. "/" .. module.config.public.name)))

        local generated = vim.list_extend(
            {"* Index"},
            modules.get_module_config("core.summary").strategy(
                dirman.get_norg_files(dirman.get_current_workspace()[1]) or {},
                ws_root,
                2,
                {}
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
    -- Add private functions here
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
