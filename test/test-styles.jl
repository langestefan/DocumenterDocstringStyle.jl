@testitem "TOML style file" tags = [:unit, :fast] begin
    using DocumenterDocstringStyle
    using DocumenterDocstringStyle: load_style, resolve_theme, layout
    dir = joinpath(@__DIR__, "fixtures", "styles")
    spec = load_style(joinpath(dir, "acme.toml"))
    @test spec.name === :acme
    @test spec.extends === :pydata
    @test spec.params === :table
    @test spec.css == [joinpath(dir, "acme-extra.css")]
    t = resolve_theme(joinpath(dir, "acme.toml"))
    @test t.section_header === :bar                     # from :pydata
    @test t.labels[:keywords] == "Other Parameters"
    @test t.labels[:throws] == "Raises"                 # from :pydata
    @test layout(t, :throws, :params) === :bullets
    @test t.tokens["accent"] == "#9558B2"
    @test t.tokens_dark["accent"] == "#c796e2"
    @test joinpath(dir, "acme-extra.css") in t.css
end

@testitem "Invalid style files name the file and the key" tags = [:unit, :fast] begin
    using DocumenterDocstringStyle: resolve_theme
    dir = joinpath(@__DIR__, "fixtures", "styles")
    cases = [
        "unknown-key.toml" => r"unknown-key\.toml: unknown key `colour`, allowed: name",
        "unknown-layout.toml" => r"unknown-layout\.toml: unknown `params` value \"grid\", allowed: \"rows\"",
        "unknown-token.toml" => r"unknown-token\.toml: unknown token `tokens\.colour`, allowed: accent",
        "key-after-table.toml" => r"key-after-table\.toml: `labels\.params` looks like a top-level key placed after the `\[labels\]` table",
        "missing-css.toml" => r"missing-css\.toml: `css` entry \"missing\.css\" not found",
        "cyclic.toml" => r"cyclic\.toml: cyclic `extends`",
    ]
    for (file, msg) in cases
        @test_throws msg resolve_theme(joinpath(dir, file))
    end
end

@testitem "Style file in a build" tags = [:integration] setup = [DocsBuild] begin
    using DocumenterDocstringStyle
    toml = joinpath(@__DIR__, "fixtures", "styles", "acme.toml")
    dir = DocsBuild.build(; plugins = [SchemaConfig(theme = toml)])
    html = DocsBuild.docstring_html(dir, "conv2d")
    @test occursin("ds-theme-acme", html)
    @test occursin("ds-params-table", html)
    @test occursin("Other Parameters", html)
    assets = joinpath(dir, "assets", "documenterdocstringstyle")
    @test isfile(joinpath(assets, "acme-acme-extra.css"))
    @test occursin("--ds-accent: #9558B2;", read(joinpath(assets, "tokens-acme.css"), String))
end

@testitem "Registered style works by symbol" tags = [:integration] setup = [DocsBuild] begin
    using DocumenterDocstringStyle
    register_theme!(:house, ThemeSpec(name = :house, extends = :numpydoc, tokens = Dict("accent" => "#123456")))
    dir = DocsBuild.build(; plugins = [SchemaConfig(theme = :house)])
    html = DocsBuild.docstring_html(dir, "conv2d")
    @test occursin("ds-theme-house", html)
    @test occursin("ds-params-deflist", html)
end

@testitem "@docstyle switches the theme from its position" tags = [:integration] setup = [DocsBuild] begin
    using DocumenterDocstringStyle
    dir = DocsBuild.build(; plugins = [SchemaConfig(theme = :labeled)])
    @test occursin("ds-theme-labeled", DocsBuild.docstring_html(dir, "conv2d"))
    @test occursin("ds-theme-pydata", DocsBuild.docstring_html(dir, "splat"; page = "styles.html"))
    @test occursin("ds-theme-table", DocsBuild.docstring_html(dir, "typed"; page = "styles.html"))
    for theme in (:labeled, :pydata, :table)
        @test isfile(joinpath(dir, "assets", "documenterdocstringstyle", "tokens-$theme.css"))
    end
    @test !occursin("@docstyle", read(joinpath(dir, "styles.html"), String))
end

@testitem "preview" tags = [:integration, :slow] begin
    using DocumenterDocstringStyle
    index = DocumenterDocstringStyle.preview(:numpydoc; open = false)
    @test occursin("ds-theme-numpydoc", read(index, String))
    toml = joinpath(@__DIR__, "fixtures", "styles", "acme.toml")
    index = DocumenterDocstringStyle.preview(toml; open = false)
    @test occursin("ds-theme-acme", read(index, String))
    elapsed = @elapsed index = DocumenterDocstringStyle.preview(:all; open = false)
    @test elapsed < 30
    for theme in (:labeled, :pydata, :numpydoc, :table, :rustdoc)
        html = read(joinpath(dirname(index), "$theme.html"), String)
        @test occursin("ds-theme-$theme", html)
        # DocumenterCitations resolved the citation inside the References section.
        refs = match(r"<div class=\"ds-section ds-section-references.*?</div>\n</div>"s, html)
        @test refs !== nothing
        @test occursin("bibliography.html#DumoulinVisin2016", refs.match)
        @test !occursin("@cite", refs.match)
    end
end
