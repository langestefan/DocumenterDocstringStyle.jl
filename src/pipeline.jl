# Documenter pipeline steps. Each one is a no-op unless the user passed a
# `SchemaConfig` in `makedocs(plugins = [...])`. `Documenter.getplugin` would
# construct a default config, so check `doc.plugins` directly.

function schema_config(doc::Documenter.Document)
    haskey(doc.plugins, SchemaConfig) || return nothing
    return doc.plugins[SchemaConfig]::SchemaConfig
end

# Runs the schema check after Documenter's own CheckDocument (4.0).
abstract type CheckSchema <: Documenter.Builder.DocumentPipeline end

Documenter.Selectors.order(::Type{CheckSchema}) = 4.1

function Documenter.Selectors.runner(::Type{CheckSchema}, doc::Documenter.Document)
    config = schema_config(doc)
    config === nothing && return
    @info "CheckSchema: checking docstrings against the schema."
    problems = Problem[]
    for mod in doc.blueprint.modules
        append!(problems, check_module(mod; config))
    end
    isempty(problems) && return
    report = sprint(show, MIME"text/plain"(), problems)
    if config.strict && any(p -> p.severity === :error, problems)
        error(report)
    end
    @warn report
    return
end

# Themes used during the build, collected by TransformSchema for AssetStep.
mutable struct SchemaState <: Documenter.Plugin
    themes::Vector{DocstringTheme}
end
SchemaState() = SchemaState(DocstringTheme[])

# Resolve a theme once at build start and check its stylesheets exist. TOML
# paths are relative to the directory of `make.jl`.
function resolve_build_theme(theme, doc::Documenter.Document)
    t = resolve_theme(theme isa AbstractString ? css_path(theme, doc) : theme)
    for css in stylesheets(t)
        isfile(css_path(css, doc)) || error("theme `$(theme_name(t))`: stylesheet `$css` not found")
    end
    return t
end

css_path(css, doc) = isabspath(css) ? css : joinpath(doc.user.root, css)

# Visit nodes in document order.
function walk(f, node::Node)
    f(node)
    for child in collect(node.children)
        walk(f, child)
    end
    return
end

# Replaces docstring sections with the theme's nodes. Must finish before
# DocumenterCodeBlocks scans code blocks at 4.5.
abstract type TransformSchema <: Documenter.Builder.DocumentPipeline end

Documenter.Selectors.order(::Type{TransformSchema}) = 4.2

function Documenter.Selectors.runner(::Type{TransformSchema}, doc::Documenter.Document)
    config = schema_config(doc)
    config === nothing && return
    state = Documenter.getplugin(doc, SchemaState)
    cache = Dict{Any, DocstringTheme}()
    get_theme(x) = get!(() -> resolve_build_theme(x, doc), cache, x)
    default = get_theme(config.theme)
    for page in values(doc.blueprint.pages)
        theme = default
        walk(page.mdast) do node
            e = node.element
            if e isa Documenter.MetaNode && haskey(e.dict, DOCSTYLE_KEY)
                theme = get_theme(e.dict[DOCSTYLE_KEY])
            elseif e isa Documenter.DocsNode
                binding = e.object.binding
                for (i, (ast, ds)) in enumerate(zip(e.mdasts, e.results))
                    # Same id Documenter gives the docstring, one prefix per method docstring.
                    anchor = i == 1 ? e.anchor.id : "$(e.anchor.id)-$i"
                    if transform_docstring!(ast, ds, binding, theme, config; anchor)
                        any(t -> theme_name(t) === theme_name(theme), state.themes) || push!(state.themes, theme)
                    end
                end
            end
        end
    end
    return
end

# Copies the stylesheets of the themes in use into the build and registers
# them with the HTML format. Runs before DocumenterCodeBlocks' assets (5.5).
abstract type AssetStep <: Documenter.Builder.DocumentPipeline end

Documenter.Selectors.order(::Type{AssetStep}) = 5.4

const ASSET_SUBDIR = "documenterdocstringstyle"

function Documenter.Selectors.runner(::Type{AssetStep}, doc::Documenter.Document)
    schema_config(doc) === nothing && return
    themes = Documenter.getplugin(doc, SchemaState).themes
    isempty(themes) && return
    dest = joinpath(doc.user.build, "assets", ASSET_SUBDIR)
    mkpath(dest)
    files = String[]
    for t in themes
        name = css_class(theme_name(t))
        for css in stylesheets(t)
            src = css_path(css, doc)
            file = dirname(src) == ASSET_DIR ? basename(src) : "$name-$(basename(src))"
            file in files && continue
            cp(src, joinpath(dest, file); force = true)
            push!(files, file)
        end
        file = "tokens-$name.css"
        write(joinpath(dest, file), tokens_css(t))
        push!(files, file)
    end
    for fmt in doc.user.format
        fmt isa Documenter.HTML || continue
        for file in files
            uri = "assets/$ASSET_SUBDIR/$file"
            any(a -> a isa Documenter.HTMLWriter.HTMLAsset && a.uri == uri, fmt.assets) ||
                push!(fmt.assets, Documenter.asset(uri; islocal = true))
        end
    end
    return
end
