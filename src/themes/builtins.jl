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

const PYTHON_LABELS = Dict(:arguments => "Parameters", :keywords => "Keyword Arguments", :throws => "Raises")

# PyTorch docs (pydata-sphinx-theme): shaded "Parameters:" bars and bullets,
# **name** (type) – description, then "Default: `1`".
register_builtin!(
    ThemeSpec(;
        name = :pydata,
        section_header = :bar,
        params = :bullets,
        default = :suffix,
        labels = PYTHON_LABELS,
        tokens = Dict("accent" => "#0a7d91", "label-bg" => "#eef1f4"),
        tokens_dark = Dict("accent" => "#4fb2c9", "label-bg" => "#2c3435"),
        css = [theme_css(:pydata)],
    )
)

# NumPy and SciPy docs (numpydoc): headings with a rule underneath and a
# definition list, `name : type, default: 1`.
register_builtin!(
    ThemeSpec(;
        name = :numpydoc,
        section_header = :heading_rule,
        params = :deflist,
        default = :in_type,
        labels = PYTHON_LABELS,
        tokens = Dict("accent" => "#013243"),
        tokens_dark = Dict("accent" => "#4dabcf"),
        css = [theme_css(:numpydoc)],
    )
)

# mkdocstrings with mkdocs-material: small bold headings and a table with
# Name, Type, Description and Default columns.
register_builtin!(
    ThemeSpec(;
        name = :table,
        section_header = :heading,
        params = :table,
        default = :column,
        tokens = Dict("accent" => "#4051b5", "label-bg" => "#f5f6fa"),
        tokens_dark = Dict("accent" => "#8c9cf5", "label-bg" => "#2c3435"),
        css = [theme_css(:table)],
    )
)

# docs.rs (rustdoc): plain headings with a bottom border and the list as written.
register_builtin!(
    ThemeSpec(;
        name = :rustdoc,
        section_header = :heading,
        params = :list,
        default = :hidden,
        tokens = Dict("accent" => "#3873ad"),
        tokens_dark = Dict("accent" => "#d2991d"),
        css = [theme_css(:rustdoc)],
    )
)
