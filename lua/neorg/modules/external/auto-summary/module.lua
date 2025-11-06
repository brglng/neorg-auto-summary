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
        local summary = module.required["core.summary"]
        local dirman = modules.get_module("core.dirman")

        if not dirman then
            utils.notify("`core.dirman` is not loaded! It is required to generate summaries")
            return
        end

        local ws_root = dirman.get_current_workspace()[2]
        local summary_path = vim.fs.normalize(vim.fs.abspath(vim.fn.resolve(ws_root .. "/" .. module.config.public.name)))

        utils.notify("Generating summary at " .. summary_path .. "...")

        local generated = modules.get_module_config("core.summary").strategy(
            dirman.get_norg_files(dirman.get_current_workspace()[1]) or {},
            ws_root,
            1,
            {}
        )

        local buf = nil
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
            local buf_path = vim.fs.normalize(vim.fs.abspath(vim.fn.resolve(vim.api.nvim_buf_get_name(b))))
            if buf_path == summary_path then
                buf = b
                break
            end
        end

        if buf then
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, generated)
            vim.api.nvim_buf_call(buf, function()
                vim.cmd("write")
            end)
        else
            vim.fn.writefile(generated, summary_path)
        end

        utils.notify("Summary generated at " .. summary_path)
    end,
}

module.private = {
    -- Add private functions here
}

module.on_event = function(event)
    vim.schedule(function()
        if event.type == "core.neorgcmd.events.auto-summary.summarize" then
            module.public.auto_summary()
        elseif (
            event.type == "core.dirman.events.workspace_changed" or
            event.type == "core.dirman.events.workspace_added" or
            event.type == "core.dirman.events.file_created"
        ) and module.config.public.autocmd then
            module.public.auto_summary()
        end
    end)
end

module.events.subscribed = {
    ["core.neorgcmd"] = {
        ["auto-summary.summarize"] = true,
    },
    ["core.dirman"] = {
        ["workspace_changed"] = true,
        ["workspace_added"] = true,
        ["file_created"] = true,
    }
}

return module
