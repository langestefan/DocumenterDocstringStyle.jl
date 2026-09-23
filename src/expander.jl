# The `@docstyle` block switches the theme from its position to the end of the
# page. It becomes a MetaNode, which every writer renders as nothing, and
# TransformSchema reads it in document order.

abstract type DocStyleBlocks <: Documenter.Expanders.ExpanderPipeline end

Documenter.Selectors.order(::Type{DocStyleBlocks}) = 2.06   # after @codeblocks (2.05)
Documenter.Selectors.matcher(::Type{DocStyleBlocks}, node, page, doc) = Documenter.iscode(node, "@docstyle")

const DOCSTYLE_KEY = :DocumenterDocstringStyle

function Documenter.Selectors.runner(::Type{DocStyleBlocks}, node, page, doc)
    x = node.element
    lines = Documenter.find_block_in_file(x.code, page.source)
    settings = Dict{Symbol, Any}()
    for (ex, _) in Documenter.parseblock(x.code, doc, page; lines)
        if Documenter.isassign(ex) && ex.args[1] === :theme
            value = ex.args[2]
            if value isa QuoteNode && value.value isa Symbol
                settings[DOCSTYLE_KEY] = value.value
            elseif value isa String
                settings[DOCSTYLE_KEY] = value
            else
                error("`@docstyle` in $(Documenter.locrepr(doc, page, lines)): `theme` must be a `:symbol` or a \"path\"")
            end
        else
            @warn "DocumenterDocstringStyle: unknown `@docstyle` option `$ex` in $(Documenter.locrepr(doc, page, lines))."
        end
    end
    node.element = Documenter.MetaNode(x, settings)
    return
end
