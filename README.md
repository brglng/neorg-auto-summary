# neorg-auto-summary

Automatic summary generation for Neorg.

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

Add the following to your Neorg plugin configuration:

```lua
{
    "nvim-neorg/neorg",
    dependencies = {
        "brglng/neorg-auto-summary",
    },
    config = function()
        require("neorg").setup({
            load = {
                ["core.defaults"] = {},
                ["core.summary"] = {}, -- Required for auto-summary
                ["external.auto-summary"] = {
                    -- Add your configuration here
                    -- config = {
                    --     summary_length = 100,
                    --     auto_update = true,
                    -- }
                },
            },
        })
    end,
}
```

## Configuration

The module can be configured through Neorg's setup function:

```lua
require("neorg").setup({
    load = {
        ["external.auto-summary"] = {
            config = {
                name = "index.norg", -- Name of the summary file
            }
        },
    },
})
```

## Usage

`:Neorg auto-summary`
