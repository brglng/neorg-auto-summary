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
            ["external.auto-summary"] = {
                config = {
                    name = "index.norg",            -- Name of the main summary file
                    autocmd = false,                 -- Whether to create an autocommand to update the summary on save
                    category_separator = ".",        -- Separator for sub-categories (e.g. "a.b.c")
                    sub_category_file = true,        -- Put each sub-category summary in a separate file
                    categories_dir = "categories",   -- Root subdirectory for sub-category summary files
                    list_children_in_parent = true,  -- List all descendant norg files in parent summary files
                }
            },
        },
    }
}
```

## Usage

`:Neorg auto-summary`

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | string | `"index.norg"` | Name of the main summary file. |
| `autocmd` | boolean | `false` | When `true`, automatically regenerates the summary on every `.norg` file save. |
| `category_separator` | string | `"."` | Separator for sub-categories in the `categories` metadata field. For example, `"a.b.c"` splits into three levels. |
| `sub_category_file` | boolean | `true` | When `true`, each sub-category summary is written to a separate file under the `categories_dir`. When `false`, sub-categories are rendered as nested headings in the main summary file. |
| `categories_dir` | string | `"categories"` | Root subdirectory (relative to workspace root) where sub-category summary files are stored. Only used when `sub_category_file` is `true`. |
| `list_children_in_parent` | boolean | `true` | When `true` (and `sub_category_file` is `true`), all descendant norg files are listed in each parent's summary file, flattened under the top-level heading. |

## Sub-category File Structure

When `sub_category_file` is enabled, category summary files are organized under the `categories_dir`:

- **All categories**: `<categories_dir>/<path>/<category_name>.norg`

For example, given files with categories `a.b.c`, `a.b.d`, `a.e`, and `f`:

```
categories/
├── a/
│   ├── b/
│   │   ├── c.norg          # summary for category "a.b.c"
│   │   └── d.norg          # summary for category "a.b.d"
│   ├── b.norg              # summary for category "a.b"
│   └── e.norg              # summary for category "a.e"
├── a.norg                  # summary for category "a"
└── f.norg                  # summary for category "f"
```

Each category's summary file lists its first-level children as headings (sorted alphabetically) that link to the corresponding sub-category summary files, followed by note file entries (also sorted alphabetically and deduplicated). When `list_children_in_parent` is enabled, all descendant norg files are also listed under the top-level heading.
