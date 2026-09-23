# [Custom styles](@id custom-styles)

A style decides how a docstring renders; the [schema](@ref schema) decides what authors write. The source never changes between styles. There are four levels, each building on the one before.

| Level | How | Typical use |
| :--- | :--- | :--- |
| 1. Pick | `theme = :pydata` | Use a built-in style as is |
| 2. Tweak | `theme = ThemeSpec(extends = :pydata, ...)` | Brand colors, relabel a section, swap one layout |
| 3. Style file | `theme = "docstyle.toml"` | Keep the style next to the docs, editable without Julia |
| 4. Share | `register_theme!(:acme, spec)`, then `theme = :acme` | One house style across many packages |

## Tweak a built-in style

A [`ThemeSpec`](@ref) extends a registered theme and overrides only what it sets:

```julia
SchemaConfig(;
    theme = ThemeSpec(;
        name = :brand,
        extends = :pydata,
        params = :table,
        labels = Dict(:keywords => "Other Parameters"),
        tokens = Dict("accent" => "#9558B2"),
        tokens_dark = Dict("accent" => "#c796e2"),
    ),
)
```

Every built-in theme is a `ThemeSpec` too, so anything they do, a custom style can do.

## Style files

A TOML file mirrors `ThemeSpec`. Paths are relative to the directory of `make.jl`, and `css` paths are relative to the style file:

```toml
# docs/docstyle.toml  (top-level keys must come before any [table])
name    = "acme"
extends = "pydata"
params  = "table"
css     = ["src/assets/acme-extra.css"]

[labels]
keywords = "Other Parameters"

[sections.throws]
params = "bullets"

[tokens]
accent   = "#9558B2"
label-bg = "#f3eef7"

[tokens_dark]
accent = "#c796e2"
```

Use it with `SchemaConfig(theme = "docstyle.toml")`. Mistakes fail at the start of the build with an error that names the file, the key and the allowed values.

## Layout primitives

The built-in styles are combinations of these, and a custom style can mix them freely. `sections` overrides them for one section, such as `[sections.throws]`.

| Field | Value | Output |
| :--- | :--- | :--- |
| `section_header` | `:label_column` | Label in a left column (Labeled) |
|  | `:bar` | Full-width shaded bar with a trailing colon (PyData) |
|  | `:heading_rule` | Heading with a rule underneath (Numpydoc) |
|  | `:heading` | Plain heading (Table, Rustdoc) |
| `params` | `:rows` | Name, type and default on one line, description below |
|  | `:bullets` | **name** (type) – description |
|  | `:deflist` | `name : type` as the term, description indented below |
|  | `:table` | Name, Type, Description and Default columns |
|  | `:list` | The bullet list as written |
| `default` | `:pill` | Outlined pill next to the type |
|  | `:suffix` | "Default: `1`" after the description |
|  | `:in_type` | `type, default: 1` |
|  | `:column` | Its own table column |
|  | `:hidden` | Not shown |

A table cell holds one block, so a table falls back to rows for a section whose descriptions have several paragraphs.

## Design tokens

Theme stylesheets read colors and sizes only from CSS custom properties, so `tokens` restyle any theme: `accent`, `text`, `muted`, `border`, `label-bg`, `code-bg`, `error`, `note`, `warning`, `font-body`, `font-mono`, `label-width` and `radius`. `tokens_dark` applies under Documenter's dark theme.

Extra rules go in the `css` files. Root them at `.ds-theme-<name>` so several styles can share a site, and never set `overflow: hidden` on a docstring container, or DocumenterCodeBlocks' tooltips get clipped.

## Per-page styles

An `@docstyle` block switches the style from its position to the end of the page. It takes the same values as `theme`:

````markdown
```@docstyle
theme = :table
```
````

The [Styles](styles/labeled.md) pages of these docs each use one.

## Share a style

A style package exports a `ThemeSpec` and registers it when it loads:

```julia
module AcmeDocStyle

using DocumenterDocstringStyle

const THEME = ThemeSpec(;
    name = :acme,
    extends = :pydata,
    css = [joinpath(pkgdir(@__MODULE__), "assets", "acme.css")],
)

__init__() = register_theme!(:acme, THEME)

end
```

Other packages then use `theme = :acme`. Built-in names cannot be registered again.

## Preview

`DocumenterDocstringStyle.preview` builds a small site with the demo docstrings, which makes iterating on a style file quick:

```julia
DocumenterDocstringStyle.preview("docs/docstyle.toml")
```
