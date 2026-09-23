"""
    DocstringTheme

Supertype of docstring themes.

A theme decides how the sections of a full-tier docstring render. Subtypes
override only what they need; every method has a default that reproduces the
`:labeled` theme. Most users want a [`ThemeSpec`](@ref) instead.

The interface is `theme_name`, `section_label`, `render_section`,
`render_params` and `stylesheets`.
"""
abstract type DocstringTheme end

# Name used in the `ds-theme-<name>` CSS class.
theme_name(::DocstringTheme) = :labeled

# Display label of a section; `default` is the schema name.
section_label(::DocstringTheme, ::Symbol, default::String) = default

render_section(::DocstringTheme, s::Section, ctx) = render_section(builtin_theme(:labeled), s, ctx)

render_params(::DocstringTheme, s::Section, ctx) = render_params(builtin_theme(:labeled), s, ctx)

# Absolute paths of the CSS files the theme needs.
stylesheets(::DocstringTheme) = stylesheets(builtin_theme(:labeled))

# Design tokens as `(light, dark)` dictionaries.
theme_tokens(::DocstringTheme) = theme_tokens(builtin_theme(:labeled))

# Whether the theme transforms docstrings at all; `:plain` does not.
transforms(::DocstringTheme) = true
