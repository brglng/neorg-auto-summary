# neorg-auto-summary

Automatic summary generation for Neorg.

A Neorg module that provides automatic summary generation capabilities for your Neorg documents.

## Features

- 🚀 Seamless integration with Neorg
- 📝 Automatic summary generation
- ⚙️ Configurable options
- 🔌 Easy installation with lazy.nvim

## Requirements

- [Neovim](https://neovim.io/) >= 0.8.0
- [Neorg](https://github.com/nvim-neorg/neorg)

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
                ["external.auto_summary"] = {
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

### Using other plugin managers

This plugin follows the standard Neovim plugin structure and should work with any plugin manager. Just ensure that:

1. The plugin is installed before Neorg is loaded
2. Neorg is configured to load the `external.auto_summary` module

## Configuration

The module can be configured through Neorg's setup function:

```lua
require("neorg").setup({
    load = {
        ["external.auto_summary"] = {
            config = {
                -- Add your configuration options here
            }
        },
    },
})
```

## Usage

Once installed and configured, the module will be automatically loaded by Neorg when you open `.norg` files.

<!-- Add usage examples here as features are implemented -->

## Development

This project uses [StyLua](https://github.com/JohnnyMorganz/StyLua) for Lua code formatting.

### Project Structure

```
neorg-auto-summary/
├── lua/
│   └── neorg/
│       └── modules/
│           └── external/
│               └── auto_summary/
│                   └── module.lua          # Main module definition
├── plugin/
│   └── neorg-auto-summary.lua              # Plugin entry point (optional)
├── README.md                                # This file
├── LICENSE                                  # License file
└── .gitignore                               # Git ignore rules
```

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) file for details

## Acknowledgments

- [Neorg](https://github.com/nvim-neorg/neorg) - The Neovim organization tool
- Inspired by other Neorg external modules like [neorg-templates](https://github.com/pysan3/neorg-templates)
