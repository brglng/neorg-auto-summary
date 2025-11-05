--[[
    file: neorg-auto-summary.lua
    title: Neorg Auto Summary Plugin Entry Point
    description: Plugin entry point that runs on Neovim startup
--]]

-- This file is executed when Neovim starts
-- It can be used for any initialization that needs to happen before the module loads
-- For most cases, this file can remain minimal or empty

-- Check if Neorg is available
if vim.fn.exists(":Neorg") == 0 then
    -- Neorg command doesn't exist yet, which is fine during lazy loading
    return
end

-- Optional: Set up any global configurations or autocommands here
-- Example:
-- vim.api.nvim_create_autocmd("FileType", {
--     pattern = "norg",
--     callback = function()
--         -- Do something when a .norg file is opened
--     end,
-- })
