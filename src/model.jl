# Theme-independent model of a full-tier docstring, built from Documenter's
# MarkdownAST. Nodes are the originals: rendering moves them, never copies them.

const Node = MarkdownAST.Node{Nothing}

"""
    Param

One parameter item of an `Arguments`, `Keywords` or `Throws` section.

# Fields
- `name::String`: the name inside the leading code span.
- `type::Union{Nothing,String}`: the `::Type` part, if any.
- `default::Union{Nothing,String}`: the `= default` part, if any.
- `item::Node`: the list item; [`take_description!`](@ref) extracts its description.
"""
struct Param
    name::String
    type::Union{Nothing, String}
    default::Union{Nothing, String}
    item::Node
end

"""
    Section

One level-1 section of a docstring.

# Fields
- `id::Symbol`: section id, e.g. `:see_also` for `# See also`.
- `name::String`: the section name as written.
- `blocks::Vector{Node}`: the section's original block nodes.
- `params::Union{Nothing,Vector{Param}}`: parsed items for parameter sections.
- `na::Bool`: whether the section is an explicit N/A opt-out.
"""
struct Section
    id::Symbol
    name::String
    blocks::Vector{Node}
    params::Union{Nothing, Vector{Param}}
    na::Bool
end

const PARAM_SECTIONS = (:arguments, :keywords, :throws)

section_id(name) = Symbol(replace(lowercase(strip(name)), r"\s+" => "_"))

# Items of a section that is exactly one list whose items all start with a code span.
function parse_params(blocks::Vector{Node})
    length(blocks) == 1 && blocks[1].element isa MarkdownAST.List || return nothing
    params = Param[]
    for item in blocks[1].children
        code = leading_code(item)
        code === nothing && return nothing
        p = parse_param_item(code.element.code)
        isempty(p.name) && return nothing
        push!(params, Param(p.name, p.type, p.default, item))
    end
    return params
end

function leading_code(item::Node)
    para = item.first_child
    (para === nothing || !(para.element isa MarkdownAST.Paragraph)) && return nothing
    code = para.first_child
    return code !== nothing && code.element isa MarkdownAST.Code ? code : nothing
end

"""
    take_description!(p::Param) -> Vector{Node}

Remove the leading code span and the `:` after it from `p.item`, and return the
remaining block nodes, which form the description.

$(MINIMAL)
"""
function take_description!(p::Param)
    code = leading_code(p.item)
    if code !== nothing
        para = code.parent::Node
        MarkdownAST.unlink!(code)
        text = para.first_child
        if text !== nothing && text.element isa MarkdownAST.Text
            rest = lstrip(text.element.text)
            rest = startswith(rest, ':') ? lstrip(rest[2:end]) : rest
            isempty(rest) ? MarkdownAST.unlink!(text) : (text.element.text = rest)
        end
        para.first_child === nothing && MarkdownAST.unlink!(para)
    end
    return collect(p.item.children)
end

# Split a docstring AST into its preamble and sections. Documenter turns
# headings into bold paragraphs, so section boundaries come from the parsed
# docstring, whose flattened blocks match the AST's children one to one.
# Returns `nothing` when they do not line up.
function build_model(ast::Node, ds::Base.Docs.DocStr, config::SchemaConfig)
    blocks = flatten(Base.Docs.parsedoc(ds))
    kids = collect(ast.children)
    length(blocks) == length(kids) || return nothing
    starts = findall(b -> b isa Markdown.Header{1}, blocks)
    sections = Section[]
    for (k, i) in enumerate(starts)
        stop = k < length(starts) ? starts[k + 1] - 1 : length(kids)
        name = String(strip(inline_string(blocks[i].text)))
        body = kids[(i + 1):stop]
        id = section_id(name)
        params = id in PARAM_SECTIONS ? parse_params(body) : nothing
        na = is_na(blocks[(i + 1):stop], config.na_markers)
        push!(sections, Section(id, name, body, params, na))
    end
    headers = kids[starts]
    return (; headers, sections)
end
