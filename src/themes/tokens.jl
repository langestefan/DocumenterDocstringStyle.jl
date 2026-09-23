# Design tokens: every theme stylesheet reads colors and sizes only from these
# CSS custom properties (`--ds-<name>`), so `tokens` can restyle any theme.
const TOKENS = (
    "accent", "text", "muted", "border", "label-bg", "code-bg", "error", "note",
    "warning", "font-body", "font-mono", "label-width", "radius",
)

function validate_tokens(spec::ThemeSpec)
    for (field, tokens) in (("tokens", spec.tokens), ("tokens_dark", spec.tokens_dark))
        for name in keys(tokens)
            name in TOKENS ||
                error("theme `$(spec.name)`: unknown token `$name` in $field, allowed: $(join(TOKENS, ", "))")
        end
    end
    return
end

# Stylesheet setting the theme's tokens, light first, dark values under
# Documenter's dark theme class.
function tokens_css(t::DocstringTheme)
    name = theme_name(t)
    light, dark = theme_tokens(t)
    root = ".ds-theme-$name, details.docstring:has(.ds-theme-$name)"
    dark_root = join(("html.theme--documenter-dark $s" for s in split(root, ", ")), ", ")
    io = IOBuffer()
    for (selector, tokens) in ((root, light), (dark_root, dark))
        isempty(tokens) && continue
        println(io, selector, " {")
        for key in sort!(collect(keys(tokens)))
            println(io, "  --ds-", key, ": ", tokens[key], ";")
        end
        println(io, "}")
    end
    return String(take!(io))
end
