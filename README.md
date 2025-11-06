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
    opts = {
        load = {
            ["core.defaults"] = {},
            ["core.summary"] = {}, -- Required for auto-summary
            ["external.auto-summary"] = {
                config = {
                    name = "index.norg", -- Name of the summary file
                }
            },
        },
    }
    end,
}
```

## Usage

`:Neorg auto-summary`
