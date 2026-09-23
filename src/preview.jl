const PREVIEW_DEMO = normpath(joinpath(@__DIR__, "..", "assets", "preview", "ConvDemo.jl"))
const PREVIEW_BIB = normpath(joinpath(@__DIR__, "..", "assets", "preview", "refs.bib"))
const PREVIEW_DOCS = ["conv2d", "Conv2d", "conv_transpose2d", "channels", "reset_cache!"]

"""
    preview(theme = :labeled; open::Bool = true) -> String

Build a throwaway site that renders the demo docstrings with `theme`.

The site is built in a temporary directory, with DocumenterCodeBlocks and
DocumenterCitations when they are installed. Use it to iterate on a style file.

# Arguments
- `theme = :labeled`: anything `SchemaConfig(theme = ...)` accepts, including a
  TOML path. `:all` renders every registered theme, one page each.

# Keywords
- `open::Bool = true`: open the built page in the browser.

# Returns
The path of the built `index.html`.

# Examples
```jldoctest
julia> using DocumenterDocstringStyle

julia> isfile(DocumenterDocstringStyle.preview(:pydata; open = false))
true
```
"""
function preview(theme = :labeled; open::Bool = true)
    demo = demo_module()
    codeblocks = optional_module("DocumenterCodeBlocks")
    citations = optional_module("DocumenterCitations")
    # The demo module and the optional plugins may be newer than this call's world.
    return Base.invokelatest(build_preview, theme, open, demo, codeblocks, citations)
end

# The demo module lives in `Main` so `@docs` blocks can find it.
function demo_module()
    name = :ConvDemo
    isdefined(Main, name) || return Base.include(Main, PREVIEW_DEMO)::Module
    return Base.invokelatest(getglobal, Main, name)::Module
end

function build_preview(theme, open::Bool, demo::Module, codeblocks, citations)
    themes = theme === :all ? preview_themes() : Any[theme isa AbstractString ? abspath(theme) : theme]
    dir = mktempdir()
    src = joinpath(dir, "src")
    mkpath(src)
    pages = Any["index.md"]
    for (i, t) in enumerate(themes)
        file = length(themes) == 1 ? "index.md" : "$(preview_name(t)).md"
        write(joinpath(src, file), preview_page(t; canonical = i == 1))
        file == "index.md" || push!(pages, preview_name(t) => file)
    end
    if length(themes) > 1
        links = join(("- [`$(repr(t))`]($(preview_name(t)).md)" for t in themes), "\n")
        write(joinpath(src, "index.md"), "# Theme preview\n\nOne page per registered theme.\n\n$links\n")
    end
    plugins = Any[SchemaConfig(; theme = first(themes), strict = false)]
    codeblocks === nothing || push!(plugins, getfield(codeblocks, :CodeBlocks)())
    if citations !== nothing
        push!(plugins, getfield(citations, :CitationBibliography)(PREVIEW_BIB))
        write(joinpath(src, "bibliography.md"), "# Bibliography\n\n```@bibliography\n```\n")
        push!(pages, "Bibliography" => "bibliography.md")
    end
    Logging.with_logger(Logging.ConsoleLogger(stderr, Logging.Warn)) do
        Documenter.makedocs(;
            root = dir, source = "src", build = "build", sitename = "DocumenterDocstringStyle preview",
            modules = [demo], pages, plugins, remotes = nothing, doctest = false, checkdocs = :none,
            warnonly = true, format = Documenter.HTML(; prettyurls = false, inventory_version = "0", repolink = nothing, edit_link = nothing),
        )
    end
    index = joinpath(dir, "build", "index.html")
    open && open_in_browser(index)
    return index
end

preview_name(t) = t isa AbstractString ? css_class(splitext(basename(t))[1]) : css_class(t)

# Every registered theme that resolves, built-ins first.
function preview_themes()
    names = [BUILTIN_THEMES; sort!(setdiff(collect(keys(THEMES)), BUILTIN_THEMES))]
    return Any[n for n in names if try_resolve(n)]
end

function try_resolve(name)
    try
        resolve_theme(name)
        return true
    catch err
        @warn "DocumenterDocstringStyle: skipping theme `:$name` in the preview" exception = err
        return false
    end
end

function preview_page(theme; canonical::Bool)
    title = theme isa AbstractString ? basename(theme) : string(theme)
    docs = canonical ? "@docs" : "@docs; canonical=false"
    return """
    # $title

    ```@docstyle
    theme = $(repr(theme))
    ```

    ```@meta
    CurrentModule = Main.ConvDemo
    ```

    ```$docs
    $(join(PREVIEW_DOCS, "\n"))
    ```
    """
end

# The package `name` when it is installed, else `nothing`.
function optional_module(name)
    id = Base.identify_package(name)
    return id === nothing ? nothing : Base.require(id)
end

function open_in_browser(path)
    cmd = Sys.isapple() ? `open $path` : Sys.iswindows() ? `cmd /c start "" $path` : `xdg-open $path`
    try
        run(pipeline(cmd; stdout = devnull, stderr = devnull); wait = false)
    catch
        @info "Open $path in a browser."
    end
    return
end
