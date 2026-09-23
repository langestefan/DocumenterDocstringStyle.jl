# Layout primitives for ThemeSpec. The HTML skeleton is the same for every
# theme; the `ds-header-*`, `ds-params-*` and `ds-default-*` classes select the
# layout in base.css. Wrappers are block-level raw HTML; names, types and
# defaults are MarkdownAST `Code` nodes inside a `Paragraph`.

raw(html::AbstractString) = MarkdownAST.Node(Documenter.RawNode(:html, html))

function code_paragraph(s::AbstractString)
    p = MarkdownAST.Node(MarkdownAST.Paragraph())
    push!(p.children, MarkdownAST.Node(MarkdownAST.Code(s)))
    return p
end

html_escape(s) = replace(string(s), "&" => "&amp;", "<" => "&lt;", ">" => "&gt;", "\"" => "&quot;")

css_class(x) = replace(string(x), r"[^A-Za-z0-9_-]" => "-")

function render_section(t::ThemeSpec, s::Section, ctx)
    header = layout(t, s.id, :section_header)
    classes = "ds-section ds-section-$(css_class(s.id)) ds-header-$header" * (s.na ? " ds-na" : "")
    label = section_label(t, s.id, s.name)
    nodes = Node[
        raw("<div class=\"$classes\">"),
        raw("<div class=\"ds-label\">$(html_escape(label))</div>"),
        raw("<div class=\"ds-content\">"),
    ]
    if s.params === nothing || s.na || layout(t, s.id, :params) === :list
        append!(nodes, s.blocks)
    else
        append!(nodes, render_params(t, s, ctx))
    end
    push!(nodes, raw("</div>\n</div>"))
    return nodes
end

function render_params(t::ThemeSpec, s::Section, ctx)
    style = layout(t, s.id, :params)
    default = layout(t, s.id, :default)
    descriptions = [take_description!(p) for p in s.params]
    if style === :table
        # Markdown table cells hold inline content only, so a description with
        # several blocks falls back to rows.
        all(d -> length(d) <= 1, descriptions) && return render_table(s.params, descriptions, default)
        @info "DocumenterDocstringStyle: `# $(s.name)` of $(ctx.binding) has a multi-block description; using rows instead of a table."
        style = :rows
    end
    nodes = Node[raw("<div class=\"ds-params ds-params-$style ds-defaults-$default\">")]
    for (p, description) in zip(s.params, descriptions)
        push!(nodes, raw("<div class=\"ds-param\">\n<div class=\"ds-param-sig\">"))
        push!(nodes, raw("<div class=\"ds-name\">"), code_paragraph(p.name), raw("</div>"))
        if p.type !== nothing
            push!(nodes, raw("<div class=\"ds-type\">"), code_paragraph(p.type), raw("</div>"))
        end
        if p.default !== nothing && default in (:pill, :in_type, :column)
            push!(nodes, raw("<div class=\"ds-default\">"), code_paragraph(p.default), raw("</div>"))
        end
        push!(nodes, raw("</div>\n<div class=\"ds-param-desc\">"))
        append!(nodes, description)
        push!(nodes, raw("</div>"))
        if p.default !== nothing && default === :suffix
            push!(nodes, raw("<div class=\"ds-default ds-default-suffix\">"), code_paragraph(p.default), raw("</div>"))
        end
        push!(nodes, raw("</div>"))
    end
    push!(nodes, raw("</div>"))
    return nodes
end

function render_table(params, descriptions, default)
    show_type = any(p -> p.type !== nothing, params)
    show_default = default !== :hidden && any(p -> p.default !== nothing, params)
    head = "<th>Name</th>" * (show_type ? "<th>Type</th>" : "") * "<th>Description</th>" *
        (show_default ? "<th>Default</th>" : "")
    nodes = Node[raw("<table class=\"ds-params ds-params-table\">\n<thead><tr>$head</tr></thead>\n<tbody>")]
    cell(content) = [raw("<td>"); content; raw("</td>")]
    for (p, description) in zip(params, descriptions)
        push!(nodes, raw("<tr>"))
        append!(nodes, cell([code_paragraph(p.name)]))
        show_type && append!(nodes, cell(p.type === nothing ? Node[] : [code_paragraph(p.type)]))
        append!(nodes, cell(description))
        show_default && append!(nodes, cell(p.default === nothing ? Node[] : [code_paragraph(p.default)]))
        push!(nodes, raw("</tr>"))
    end
    push!(nodes, raw("</tbody>\n</table>"))
    return nodes
end
