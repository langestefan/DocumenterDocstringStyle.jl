# The shared transform. Themes only see the model; this file enforces the
# guarantees that keep DocumenterCodeBlocks working inside every theme:
#
# 1. The signature block is never modified or moved, and nothing goes before it.
# 2. Code blocks are never converted to raw HTML, duplicated or reordered.
# 3. Names and types are `Code` nodes inside a `Paragraph` (see render.jl).
# 4. Wrappers are block-level raw HTML around whole sections.
# 5. Raw HTML never contains `<pre` or `<details`.

function code_blocks(node::Node, out = String[])
    node.element isa MarkdownAST.CodeBlock && push!(out, node.element.code)
    for child in node.children
        code_blocks(child, out)
    end
    return out
end

# Transform one docstring AST in place. Returns whether it was transformed.
# `anchor` is the HTML id prefix for the section headers; `nothing` for none.
function transform_docstring!(ast::Node, ds::Base.Docs.DocStr, binding, theme::DocstringTheme, config::SchemaConfig; anchor = nothing)
    transforms(theme) || return false
    isdefined(binding.mod, binding.var) || return false
    f = Base.Docs.resolve(binding)
    f isa Function && !is_excluded(config, binding, f) || return false
    any(x -> x isa Minimal || x isa NoSchema, ds.text) && return false
    model = build_model(ast, ds, config)
    (model === nothing || isempty(model.sections)) && return false

    # Take the sections out; the preamble (signature and summary) stays in place.
    foreach(MarkdownAST.unlink!, model.headers)
    kept = filter(s -> !(config.hide_na && s.na), model.sections)
    for s in model.sections, b in s.blocks
        MarkdownAST.unlink!(b)
    end
    expected = code_blocks(ast)
    for s in kept, b in s.blocks
        code_blocks(b, expected)
    end

    ctx = (; config, binding, anchor)
    out = Node[raw("<div class=\"ds-sections ds-theme-$(css_class(theme_name(theme)))\">")]
    for s in kept
        append!(out, render_section(theme, s, ctx))
    end
    push!(out, raw("</div>"))

    for n in out
        e = n.element
        if e isa Documenter.RawNode && (occursin("<pre", e.text) || occursin("<details", e.text))
            error("theme `$(theme_name(theme))` emitted raw HTML containing `<pre` or `<details`")
        end
        push!(ast.children, n)
    end
    code_blocks(ast) == expected ||
        error("theme `$(theme_name(theme))` changed the code blocks of the $(binding) docstring")
    return true
end
