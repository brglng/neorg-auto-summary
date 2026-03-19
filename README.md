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
                    name = "index.norg",            -- Name of the summary file (also used for branch category files)
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
| `name` | string | `"index.norg"` | Name of the summary file. Also used as the file name inside branch category directories. |
| `autocmd` | boolean | `false` | When `true`, automatically regenerates the summary on every `.norg` file save. |
| `category_separator` | string | `"."` | Separator for sub-categories in the `categories` metadata field. For example, `"a.b.c"` splits into three levels. |
| `sub_category_file` | boolean | `true` | When `true`, each sub-category summary is written to a separate file under the `categories_dir`. When `false`, sub-categories are rendered as nested headings in the main summary file. |
| `categories_dir` | string | `"categories"` | Root subdirectory (relative to workspace root) where sub-category summary files are stored. Only used when `sub_category_file` is `true`. |
| `list_children_in_parent` | boolean | `true` | When `true` (and `sub_category_file` is `true`), all descendant norg files are listed in each parent's summary file, flattened under the top-level heading. |

## Sub-category File Structure

When `sub_category_file` is enabled, category summary files are organized under the `categories_dir`:

- **Leaf categories** (no children): `<categories_dir>/<path>/<category_name>.norg`
- **Branch categories** (has children): `<categories_dir>/<path>/<category_name>/<name>`

For example, given files with categories `a.b.c`, `a.b.d`, `a.e`, and `f`:

```
categories/
├── a/
│   ├── index.norg          # summary for category "a"
│   ├── b/
│   │   ├── index.norg      # summary for category "a.b"
│   │   ├── c.norg          # summary for category "a.b.c"
│   │   └── d.norg          # summary for category "a.b.d"
│   └── e.norg              # summary for category "a.e"
└── f.norg                  # summary for category "f"
```

Each branch category's summary file lists its first-level children as headings that link to the corresponding sub-category summary files. When `list_children_in_parent` is enabled, all descendant norg files are also listed under the top-level heading.
