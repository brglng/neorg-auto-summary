# neorg-auto-summary Examples

This directory contains example configurations and usage patterns for the neorg-auto-summary module.

## Basic Configuration

### Minimal Setup

```lua
require("neorg").setup({
    load = {
        ["core.defaults"] = {},
        ["external.auto_summary"] = {},
    },
})
```

### With Custom Configuration

```lua
require("neorg").setup({
    load = {
        ["core.defaults"] = {},
        ["external.auto_summary"] = {
            config = {
                -- Add your configuration here when features are implemented
            }
        },
    },
})
```

## lazy.nvim Configuration

### Basic Setup

```lua
return {
    "nvim-neorg/neorg",
    dependencies = {
        "brglng/neorg-auto-summary",
    },
    ft = "norg",
    config = function()
        require("neorg").setup({
            load = {
                ["core.defaults"] = {},
                ["external.auto_summary"] = {},
            },
        })
    end,
}
```

### Advanced Setup with Dependencies

```lua
return {
    "nvim-neorg/neorg",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "brglng/neorg-auto-summary",
    },
    build = ":Neorg sync-parsers",
    ft = "norg",
    lazy = false,
    config = function()
        require("neorg").setup({
            load = {
                ["core.defaults"] = {},
                ["core.concealer"] = {},
                ["core.dirman"] = {
                    config = {
                        workspaces = {
                            notes = "~/notes",
                        },
                    },
                },
                ["external.auto_summary"] = {
                    config = {
                        -- Your configuration here
                    }
                },
            },
        })
    end,
}
```

## Usage Examples

<!-- Add usage examples here as features are implemented -->
