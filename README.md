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
                    list_children_in_parent = true,  -- List all descendant notes under each category heading
                    metadata = false,                -- Generate metadata at the top of summary files
                    sort_by = "alphabetical",        -- How to sort: "alphabetical", "created", or "updated"
                    sort_direction = "ascending",    -- Sort direction: "ascending" or "descending"
                    format_note_title = function(meta) -- Custom note title formatting callback
                        return meta.title
                    end,
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
| `list_children_in_parent` | boolean | `true` | When `true`, all descendant norg files are listed under each category heading. In file mode (`sub_category_file` is `true`), entries from sub-categories are shown under their corresponding sub-category headings. In inline mode (`sub_category_file` is `false`), all descendant entries are flattened under each heading without sub-headings. When `false`, only notes directly categorized under each category are listed; no nested sub-category headings are created. |
| `metadata` | boolean | `false` | When `true`, generates `@document.meta` at the top of summary files. For new files, fresh metadata is created via the metagen API. For existing files without metadata, it is added. For existing files with metadata whose body content changed, the `updated` timestamp is refreshed. |
| `sort_by` | string | `"alphabetical"` | How to sort headings and note entries. `"alphabetical"` sorts by title, `"created"` sorts by the note's `created` metadata timestamp, `"updated"` sorts by the note's `updated` metadata timestamp. Category headings are always sorted alphabetically. |
| `sort_direction` | string | `"ascending"` | Sort direction: `"ascending"` (A→Z or oldest→newest) or `"descending"` (Z→A or newest→oldest). |
| `format_note_title` | function | `function(meta) return meta.title end` | A callback function that receives the note's normalized metadata table and returns a formatted title string. The metadata table contains fields such as `title`, `description`, `categories`, `created`, `updated`, etc. |

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

Each category's summary file lists its first-level children as headings that link to the corresponding sub-category summary files, along with note file entries (sorted and deduplicated according to the `sort_by` and `sort_direction` settings). Sub-category headings are listed before the note entries. When `list_children_in_parent` is enabled, all descendant norg files are also listed under each sub-category heading. When disabled, only notes directly categorized under each category are listed.
