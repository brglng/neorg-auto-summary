# Contributing to neorg-auto-summary

Thank you for your interest in contributing to neorg-auto-summary! This document provides guidelines and information for contributors.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/neorg-auto-summary.git`
3. Create a new branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Commit your changes: `git commit -m "Description of changes"`
6. Push to your fork: `git push origin feature/your-feature-name`
7. Open a Pull Request

## Development Setup

### Prerequisites

- [Neovim](https://neovim.io/) >= 0.8.0
- [Neorg](https://github.com/nvim-neorg/neorg)
- [StyLua](https://github.com/JohnnyMorganz/StyLua) (for code formatting)

### Local Development

1. Clone the repository
2. Add the local path to your Neovim configuration for testing:

```lua
{
    "nvim-neorg/neorg",
    dependencies = {
        { dir = "/path/to/your/local/neorg-auto-summary" },
    },
    -- ... rest of your config
}
```

## Code Style

This project uses [StyLua](https://github.com/JohnnyMorganz/StyLua) for code formatting. The configuration is defined in `stylua.toml`.

### Running the formatter

```bash
stylua .
```

### Code Guidelines

- Follow the existing code style
- Write clear, descriptive commit messages
- Add comments for complex logic
- Keep functions small and focused
- Use meaningful variable and function names

## Project Structure

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
├── doc/
│   └── examples.md                          # Usage examples
├── README.md                                # Main documentation
├── LICENSE                                  # MIT License
├── CONTRIBUTING.md                          # This file
└── stylua.toml                              # Lua formatting config
```

## Module Development

The main module is located at `lua/neorg/modules/external/auto_summary/module.lua`.

### Module Structure

A Neorg module should follow this structure:

```lua
local neorg = require("neorg.core")
local modules = neorg.modules

local module = modules.create("external.auto_summary")

module.setup = function()
    return {
        success = true,
        requires = {
            -- List required Neorg modules here
        },
    }
end

module.load = function()
    -- Module loading logic
end

module.config.public = {
    -- Public configuration options
}

module.public = {
    -- Public API functions
}

module.private = {
    -- Private functions
}

module.on_event = function(event)
    -- Handle Neorg events
end

module.events.subscribed = {
    -- Subscribe to events
}

return module
```

## Testing

When adding new features:

1. Test with different Neorg configurations
2. Test with different plugin managers (lazy.nvim, packer, etc.)
3. Verify backward compatibility
4. Document any breaking changes

## Documentation

- Update README.md for user-facing changes
- Add examples to doc/examples.md
- Use clear, concise language
- Include code examples where appropriate

## Submitting Changes

### Pull Request Guidelines

- Provide a clear description of the changes
- Reference any related issues
- Ensure all tests pass
- Follow the code style guidelines
- Update documentation as needed

### Commit Message Format

Use clear, descriptive commit messages:

```
Add feature: brief description

Detailed explanation of what changed and why.
Include any breaking changes or migration notes.
```

## Questions or Issues?

- Open an issue for bugs or feature requests
- Use discussions for questions and ideas
- Check existing issues before opening a new one

## License

By contributing to neorg-auto-summary, you agree that your contributions will be licensed under the MIT License.

## Code of Conduct

Be respectful and constructive in all interactions. We aim to foster an inclusive and welcoming community.
