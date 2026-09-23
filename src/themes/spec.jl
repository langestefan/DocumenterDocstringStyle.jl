const SECTION_HEADERS = (:label_column, :bar, :heading_rule, :heading, :none)
const PARAM_LAYOUTS = (:rows, :bullets, :deflist, :table, :list)
const DEFAULT_STYLES = (:pill, :suffix, :in_type, :column, :hidden)
const LAYOUT_FIELDS = (section_header = SECTION_HEADERS, params = PARAM_LAYOUTS, default = DEFAULT_STYLES)

"""
    ThemeSpec(; kwargs...) -> ThemeSpec

Declarative docstring theme: a base theme plus layout choices, labels, design
tokens and extra CSS.

Fields left at `:inherit` or empty take their value from `extends`,
recursively. Every built-in theme is itself a `ThemeSpec`.

# Keywords
- `name::Symbol = :custom`: name used in the `ds-theme-<name>` CSS class.
- `extends::Union{Nothing,Symbol} = :labeled`: registered theme to inherit from.
- `section_header::Symbol = :inherit`: `:label_column`, `:bar`, `:heading_rule` or `:heading`.
- `params::Symbol = :inherit`: `:rows`, `:bullets`, `:deflist`, `:table` or `:list`.
- `default::Symbol = :inherit`: `:pill`, `:suffix`, `:in_type`, `:column` or `:hidden`.
- `labels::Dict{Symbol,String} = Dict()`: section id to display label.
- `sections::Dict{Symbol,Dict{Symbol,Symbol}} = Dict()`: per-section layout overrides.
- `tokens::Dict{String,String} = Dict()`: light-mode design tokens.
- `tokens_dark::Dict{String,String} = Dict()`: dark-mode design tokens.
- `css::Vector{String} = String[]`: extra stylesheets.

# Returns
A `ThemeSpec`.

# Examples
```jldoctest
julia> using DocumenterDocstringStyle

julia> ThemeSpec(name = :brand, tokens = Dict("accent" => "#9558B2")).extends
:labeled
```
"""
Base.@kwdef struct ThemeSpec <: DocstringTheme
    name::Symbol = :custom
    extends::Union{Nothing, Symbol} = :labeled
    section_header::Symbol = :inherit
    params::Symbol = :inherit
    default::Symbol = :inherit
    labels::Dict{Symbol, String} = Dict{Symbol, String}()
    sections::Dict{Symbol, Dict{Symbol, Symbol}} = Dict{Symbol, Dict{Symbol, Symbol}}()
    tokens::Dict{String, String} = Dict{String, String}()
    tokens_dark::Dict{String, String} = Dict{String, String}()
    css::Vector{String} = String[]
end

theme_name(t::ThemeSpec) = t.name
section_label(t::ThemeSpec, id::Symbol, default::String) = get(t.labels, id, default)
stylesheets(t::ThemeSpec) = [BASE_CSS; t.css]
theme_tokens(t::ThemeSpec) = (t.tokens, t.tokens_dark)
transforms(t::ThemeSpec) = t.section_header !== :none

# Layout choice for one section, honoring per-section overrides.
layout(t::ThemeSpec, id::Symbol, field::Symbol) = get(get(t.sections, id, Dict{Symbol, Symbol}()), field, getfield(t, field))

function validate(spec::ThemeSpec)
    for (field, allowed) in pairs(LAYOUT_FIELDS)
        value = getfield(spec, field)
        value === :inherit || value in allowed ||
            error("theme `$(spec.name)`: unknown `$field` value `:$value`, allowed: $(join(map(repr, allowed), ", "))")
    end
    for (id, overrides) in spec.sections, (field, value) in overrides
        haskey(LAYOUT_FIELDS, field) ||
            error("theme `$(spec.name)`: unknown field `$field` in sections.$id, allowed: $(join(keys(LAYOUT_FIELDS), ", "))")
        value in LAYOUT_FIELDS[field] ||
            error("theme `$(spec.name)`: unknown `$field` value `:$value` in sections.$id, allowed: $(join(map(repr, LAYOUT_FIELDS[field]), ", "))")
    end
    validate_tokens(spec)
    return spec
end

"""
    resolve(spec::ThemeSpec) -> ThemeSpec

Follow the `extends` chain and return a spec with every field set.

$(MINIMAL)
"""
function resolve(spec::ThemeSpec, seen::Vector{Symbol} = Symbol[])
    validate(spec)
    if spec.extends === nothing
        for field in keys(LAYOUT_FIELDS)
            getfield(spec, field) === :inherit &&
                error("theme `$(spec.name)` has no `extends`, so `$field` must be set")
        end
        return spec
    end
    spec.extends in seen && error("cyclic `extends` chain: $(join([seen; spec.extends], " -> "))")
    parent = resolve(lookup_theme(spec.extends), [seen; spec.extends])
    inherit(field) = getfield(spec, field) === :inherit ? getfield(parent, field) : getfield(spec, field)
    sections = Dict(k => copy(v) for (k, v) in parent.sections)
    for (k, v) in spec.sections
        sections[k] = merge(get(sections, k, Dict{Symbol, Symbol}()), v)
    end
    return ThemeSpec(;
        name = spec.name,
        extends = nothing,
        section_header = inherit(:section_header),
        params = inherit(:params),
        default = inherit(:default),
        labels = merge(parent.labels, spec.labels),
        sections,
        tokens = merge(parent.tokens, spec.tokens),
        tokens_dark = merge(parent.tokens_dark, spec.tokens_dark),
        css = unique([parent.css; spec.css]),
    )
end
