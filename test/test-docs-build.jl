@testmodule DocsBuild begin
    using Documenter

    # `@docs` blocks resolve names from `Main`, so the fixtures live there.
    if !isdefined(Main, :FixturePkg)
        Core.eval(Main, :(include($(joinpath(@__DIR__, "fixtures", "FixturePkg.jl")))))
    end
    const FixturePkg = Main.FixturePkg
    const FixtureBad = Main.FixtureBad
    const ROOT = joinpath(@__DIR__, "docs_build")

    # Build the fixture docs into a temporary directory and return its path.
    function build(; modules = [FixturePkg], plugins = [])
        dir = mktempdir()
        return build!(dir; modules, plugins)
    end

    function build!(dir; modules = [FixturePkg], plugins = [])
        makedocs(;
            root = ROOT, source = "src", build = dir, sitename = "Fixtures",
            modules, plugins, remotes = nothing, checkdocs = :none, doctest = false,
            warnonly = true, format = Documenter.HTML(; prettyurls = false, inventory_version = "0"),
        )
        return dir
    end

    # The `<details class="docstring">` fragment of `name` in a built page.
    function docstring_html(dir, name; page = "index.html")
        html = read(joinpath(dir, page), String)
        for m in eachmatch(r"<details class=\"docstring\".*?</details>"s, html)
            occursin("<code>Main.FixturePkg.$name</code>", m.match) && return m.match
        end
        error("no docstring for $name in $page")
    end
end

@testitem "Strict build passes on good docstrings" tags = [:integration] setup = [DocsBuild] begin
    using DocumenterDocstringStyle
    dir = DocsBuild.build(; plugins = [SchemaConfig(strict = true)])
    @test isfile(joinpath(dir, "index.html"))
end

@testitem "Strict build fails on bad docstrings" tags = [:integration] setup = [DocsBuild] begin
    using DocumenterDocstringStyle
    err = try
        DocsBuild.build(; modules = [DocsBuild.FixtureBad], plugins = [SchemaConfig(strict = true)])
        nothing
    catch e
        e
    end
    @test err isa ErrorException
    @test occursin("DS030 `# Arguments` misses: w", err.msg)
end

@testitem "Non-strict build warns on bad docstrings" tags = [:integration] setup = [DocsBuild] begin
    using DocumenterDocstringStyle
    @test_logs (:warn, r"^DocumenterDocstringStyle: \d+ problem\(s\)") match_mode = :any begin
        DocsBuild.build(; modules = [DocsBuild.FixtureBad], plugins = [SchemaConfig(strict = false)])
    end
end

@testitem "Loading the package without a config changes nothing" tags = [:integration, :slow] begin
    # Build the same site in two fresh processes, one with the package loaded.
    function build(load::Bool)
        dir = mktempdir()
        script = """
        using Documenter
        $(load ? "using DocumenterDocstringStyle" : "")
        module Plain
        \"\"\"
            f(x) -> Int

        Return one.
        \"\"\"
        f(x) = 1
        end
        mkpath(joinpath($(repr(dir)), "src"))
        write(joinpath($(repr(dir)), "src", "index.md"), "# Plain\\n\\n```@docs\\nMain.Plain.f\\n```\\n")
        makedocs(; root = $(repr(dir)), sitename = "Plain", modules = [Plain], remotes = nothing,
            doctest = false, format = Documenter.HTML(; prettyurls = false, inventory_version = "0"))
        """
        julia = Base.julia_cmd()
        run(pipeline(`$julia --startup-file=no --project=$(Base.active_project()) -e $script`; stdout = devnull, stderr = devnull))
        return joinpath(dir, "build")
    end
    normalize(s) = replace(
        s,
        r"<span class=\"colophon-date\"[^>]*>[^<]*</span>" => "",
        r"\"generation_timestamp\":\s*\"[^\"]*\"" => "",
    )
    plain = build(false)
    loaded = build(true)
    files(dir) = sort([relpath(joinpath(r, f), dir) for (r, _, fs) in walkdir(dir) for f in fs])
    @test files(plain) == files(loaded)
    for f in files(plain)
        @test normalize(read(joinpath(plain, f), String)) == normalize(read(joinpath(loaded, f), String))
    end
end
