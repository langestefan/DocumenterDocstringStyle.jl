@testmodule Fixtures begin
    using DocumenterDocstringStyle
    include(joinpath(@__DIR__, "fixtures", "FixturePkg.jl"))

    const PROBLEMS = check_module(FixturePkg)
    const BAD = check_module(FixtureBad)

    # Sorted problem codes reported for the function `name`.
    codes(name; problems = PROBLEMS) = sort([p.code for p in problems if p.binding.var === name])
end

@testitem "Every good fixture passes" tags = [:unit, :fast] setup = [Fixtures] begin
    @test isempty(Fixtures.PROBLEMS)
end

@testitem "conv2d reference docstring passes" tags = [:unit, :fast] setup = [Fixtures] begin
    @test isempty(Fixtures.codes(:conv2d))
end

@testitem "MINIMAL docstring passes and renders without the marker" tags = [:unit, :fast] setup = [Fixtures] begin
    @test isempty(Fixtures.codes(:channels))
    text = string(@doc Fixtures.FixturePkg.channels)
    @test !occursin("MINIMAL", text)
    @test !occursin("Minimal", text)
end

@testitem "N/A sections pass" tags = [:unit, :fast] setup = [Fixtures] begin
    @test isempty(Fixtures.codes(:reset_cache!))
end

@testitem "NOSCHEMA skips all checks" tags = [:unit, :fast] setup = [Fixtures] begin
    @test isempty(Fixtures.codes(:skipped))
end

@testitem "Bad conv2d reports the expected problems" tags = [:unit, :fast] setup = [Fixtures] begin
    @test Fixtures.codes(:conv2d; problems = Fixtures.BAD) ==
        sort([:DS002, :DS010, :DS020, :DS020, :DS030, :DS031, :DS032])
    messages = [p.message for p in Fixtures.BAD]
    @test "missing `# Returns` (write `N/A` in it to opt out)" in messages
    @test "missing `# Examples` (write `N/A` in it to opt out)" in messages
    @test "`# Arguments` misses: w" in messages
    @test "`# Arguments` lists unknown names: weight" in messages
    @test "`# Keywords` misses: groups" in messages
end

@testitem "Section order, duplicates and doctests" tags = [:unit, :fast] setup = [Fixtures] begin
    @test Fixtures.codes(:wrong_order; problems = Fixtures.BAD) == [:DS012]
    @test Fixtures.codes(:duplicate_notes; problems = Fixtures.BAD) == [:DS011]
    @test Fixtures.codes(:plain_example; problems = Fixtures.BAD) == [:DS040]
end

@testitem "Keyword item without a code span" tags = [:unit, :fast] setup = [Fixtures] begin
    @test Fixtures.codes(:bad_keyword_item; problems = Fixtures.BAD) == [:DS034]
end

@testitem "Method introspection" tags = [:unit, :fast] setup = [Fixtures] begin
    @test isempty(Fixtures.codes(:splat))
    @test isempty(Fixtures.codes(:twomethods))
    @test isempty(Fixtures.codes(:fallback))
    @test isempty(Fixtures.codes(:typed))
end

@testitem "Both markers warn and act as NOSCHEMA" tags = [:unit, :fast] setup = [Fixtures] begin
    ps = filter(p -> p.binding.var === :both_markers, Fixtures.BAD)
    @test [p.code for p in ps] == [:DS050]
    @test only(ps).severity === :warn
end

@testitem "Header rules" tags = [:unit, :fast] setup = [Fixtures] begin
    # No arguments, so only the static required sections are missing.
    @test Fixtures.codes(:nosignature; problems = Fixtures.BAD) == [:DS001, :DS002, :DS020, :DS020]
end

@testitem "Config ignore, exclude and report" tags = [:unit, :fast] setup = [Fixtures] begin
    using DocumenterDocstringStyle
    bad = Fixtures.FixtureBad
    ignored = check_module(bad; config = SchemaConfig(ignore = [:DS020]))
    @test !any(p -> p.code === :DS020, ignored)
    excluded = check_module(bad; config = SchemaConfig(exclude = Any[bad.conv2d]))
    @test !isempty(excluded)
    @test !any(p -> p.binding.var === :conv2d, excluded)

    conv = filter(p -> p.binding.var === :conv2d, Fixtures.BAD)
    report = sprint(show, MIME"text/plain"(), conv)
    @test startswith(report, "DocumenterDocstringStyle: 7 problem(s)\n  ")
    @test occursin("FixturePkg.jl:", report)
    @test occursin("\n    DS030 `# Arguments` misses: w", report)
end
