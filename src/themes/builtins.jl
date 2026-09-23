# Built-in themes. Each is a plain ThemeSpec: no theme has its own Julia
# rendering code.

function register_builtin!(spec::ThemeSpec)
    THEMES[spec.name] = validate(spec)
    push!(BUILTIN_THEMES, spec.name)
    return spec
end

theme_css(name) = joinpath(ASSET_DIR, "$name.css")

# The base of every other theme: labels in a left column, one row per parameter.
register_builtin!(
    ThemeSpec(;
        name = :labeled,
        extends = nothing,
        section_header = :label_column,
        params = :rows,
        default = :pill,
        tokens = Dict(
            "accent" => "#9558b2",
            "text" => "inherit",
            "muted" => "#6b6b6b",
            "border" => "#dbdbdb",
            "label-bg" => "#f5f5f5",
            "code-bg" => "#f5f5f5",
            "error" => "#cb3c33",
            "note" => "#4063d8",
            "warning" => "#b58900",
            "font-body" => "inherit",
            "font-mono" => "\"JuliaMono\", \"SFMono-Regular\", Menlo, Consolas, \"Liberation Mono\", \"DejaVu Sans Mono\", monospace",
            "label-width" => "8rem",
            "radius" => "4px",
        ),
        tokens_dark = Dict(
            "accent" => "#c796e2",
            "muted" => "#a3a3a3",
            "border" => "#4a5354",
            "label-bg" => "#282f2f",
            "code-bg" => "#282f2f",
            "error" => "#e06c63",
            "note" => "#7b9cf4",
            "warning" => "#e0b14f",
        ),
        css = [theme_css(:labeled)],
    )
)

# Stock Documenter output: the schema is checked, docstrings are not transformed.
register_builtin!(
    ThemeSpec(;
        name = :plain,
        extends = nothing,
        section_header = :none,
        params = :list,
        default = :hidden,
    )
)
