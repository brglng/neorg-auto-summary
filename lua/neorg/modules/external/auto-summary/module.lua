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
        local generated = modules.get_module_config("core.summary").strategy(
            dirman.get_norg_files(dirman.get_current_workspace()[1]) or {},
            ws_root,
            1,
            {}
        )

        generated = "* Index\n" .. vim.fn.join(generated, "\n") .. "\n"
        vim.uv.fs_open(
            ws_root .. "/" .. module.config.public.name,
            "w",
            tonumber("644", 8),
            function(err, fd)
                if not err and fd then
                    vim.uv.fs_write(
                        fd,
                        generated,
                        -1,
                        function(err)
                            if err then
                                utils.notify("Error writing summary file: " .. err, vim.log.levels.ERROR)
                            else
                                utils.notify("Auto-summary generated at " .. module.config.public.name)
                            end
                            vim.uv.fs_close(fd)
                        end
                    )
                else
                    utils.notify("Error opening summary file: " .. err, vim.log.levels.ERROR)
                end
            end
        )
    end,
}

module.private = {
    -- Add private functions here
}

module.on_event = function(event)
    if event.split_type[2] == "auto-summary.summarize" then
        module.public.auto_summary()
    end
end

module.events.subscribed = {
    ["core.neorgcmd"] = {
        ["auto-summary.summarize"] = true,
    },
}

return module
