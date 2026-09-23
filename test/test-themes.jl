@testitem "ThemeSpec inheritance" tags = [:unit, :fast] begin
    using DocumenterDocstringStyle
    using DocumenterDocstringStyle: resolve, resolve_theme, layout, tokens_css
    register_theme!(:t_one, ThemeSpec(name = :t_one, params = :table, tokens = Dict("accent" => "red")))
    register_theme!(
        :t_two, ThemeSpec(
            name = :t_two, extends = :t_one, labels = Dict(:keywords => "Other Parameters"),
            sections = Dict(:throws => Dict(:params => :bullets)),
        )
    )
    t = resolve_theme(ThemeSpec(name = :t_three, extends = :t_two, default = :suffix))
    @test t.extends === nothing
    @test t.section_header === :label_column   # from :labeled
    @test t.params === :table                  # from :t_one
    @test t.default === :suffix                # own
    @test t.labels[:keywords] == "Other Parameters"
    @test t.tokens["accent"] == "red"
    @test t.tokens["radius"] == "4px"
    @test layout(t, :throws, :params) === :bullets
    @test layout(t, :arguments, :params) === :table
    css = tokens_css(t)
    @test occursin(".ds-theme-t_three, details.docstring:has(.ds-theme-t_three) {", css)
    @test occursin("html.theme--documenter-dark .ds-theme-t_three", css)
    @test occursin("--ds-accent: red;", css)
end

@testitem "ThemeSpec validation" tags = [:unit, :fast] begin
    using DocumenterDocstringStyle
    using DocumenterDocstringStyle: resolve_theme
    @test_throws r"unknown `params` value `:grid`" resolve_theme(ThemeSpec(params = :grid))
    @test_throws r"unknown token `colour`" resolve_theme(ThemeSpec(tokens = Dict("colour" => "red")))
    @test_throws r"unknown field `layout` in sections.throws" resolve_theme(
        ThemeSpec(sections = Dict(:throws => Dict(:layout => :rows)))
    )
    @test_throws r"unknown theme `:nope`" resolve_theme(:nope)
    @test_throws r"must be set" resolve_theme(ThemeSpec(extends = nothing))
    @test_throws r"built-in theme" register_theme!(:labeled, ThemeSpec())
    register_theme!(:cycle_a, ThemeSpec(name = :cycle_a, extends = :cycle_b))
    register_theme!(:cycle_b, ThemeSpec(name = :cycle_b, extends = :cycle_a))
    @test_throws r"cyclic `extends` chain" resolve_theme(:cycle_a)
end

@testitem "Labeled theme keeps the transform guarantees" tags = [:integration] setup = [DocsBuild] begin
    using DocumenterDocstringStyle, DocumenterCodeBlocks, Test
    plain = DocsBuild.build(; plugins = [SchemaConfig(theme = :plain), CodeBlocks()])
    logs, labeled = Test.collect_test_logs(; min_level = Base.CoreLogging.Warn) do
        DocsBuild.build(; plugins = [SchemaConfig(theme = :labeled), CodeBlocks()])
    end
    @test !any(l -> occursin("CodeBlocks:", string(l.message)), logs)
    @test isfile(joinpath(labeled, "assets", "documenterdocstringstyle", "base.css"))
    @test isfile(joinpath(labeled, "assets", "documenterdocstringstyle", "tokens-labeled.css"))
    @test occursin("assets/documenterdocstringstyle/labeled.css", read(joinpath(labeled, "index.html"), String))

    for name in ("conv2d", "reset_cache!", "splat", "twomethods", "typed")
        html = DocsBuild.docstring_html(labeled, name)
        # 1. Signature `<pre>` directly after `<section><div>`, without a gutter.
        m = match(r"<section><div><pre[^>]*>", html)
        @test m !== nothing
        @test !occursin("line-numbers", m.match)
        # 2. Same code blocks as the untransformed build.
        @test count("<pre", html) == count("<pre", DocsBuild.docstring_html(plain, name))
    end
    conv = DocsBuild.docstring_html(labeled, "conv2d")
    @test occursin("ds-theme-labeled", conv)
    @test occursin("line-numbers", conv)                     # example keeps its gutter
    @test occursin("<div class=\"ds-name\"><p><code>x</code></p></div>", conv)
    @test !occursin("ds-theme", DocsBuild.docstring_html(labeled, "channels"))   # MINIMAL
end

@testitem "Labeled snapshot" tags = [:integration] setup = [DocsBuild] begin
    using DocumenterDocstringStyle
    dir = DocsBuild.build(; plugins = [SchemaConfig(theme = :labeled)])
    # Admonition anchors end in a hash that differs between Julia versions.
    normalize(s) = strip(replace(s, r"\s+" => " ", r"-[0-9a-f]{16}\"" => "-HASH\""))
    html = normalize(DocsBuild.docstring_html(dir, "conv2d"))
    path = joinpath(@__DIR__, "snapshots", "labeled.html")
    if get(ENV, "UPDATE_SNAPSHOTS", "") == "1" || !isfile(path)
        write(path, html * "\n")
    end
    @test html == normalize(read(path, String))
end

@testitem "hide_na drops N/A sections" tags = [:integration] setup = [DocsBuild] begin
    using DocumenterDocstringStyle
    dir = DocsBuild.build(; plugins = [SchemaConfig(theme = :labeled, hide_na = true)])
    html = DocsBuild.docstring_html(dir, "reset_cache!")
    @test !occursin("N/A", html)
end
