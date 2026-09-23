@testitem "parse_param_item" tags = [:unit, :fast] begin
    using DocumenterDocstringStyle: parse_param_item
    @test parse_param_item("x") == (name = "x", type = nothing, default = nothing)
    @test parse_param_item("x::Int") == (name = "x", type = "Int", default = nothing)
    @test parse_param_item("stride = 1") == (name = "stride", type = nothing, default = "1")
    @test parse_param_item("d::Dict{Symbol,Int} = Dict()") ==
        (name = "d", type = "Dict{Symbol,Int}", default = "Dict()")
    @test parse_param_item("T::Type{<:Real} = Float64").type == "Type{<:Real}"
    @test parse_param_item("f::Function = x -> x == 1").default == "x -> x == 1"
    @test parse_param_item("p::Pair = (a => b)").default == "(a => b)"
    @test parse_param_item("y = x::Int").default == "x::Int"
    @test parse_param_item("xs...").name == "xs..."
    @test parse_param_item("bias::Union{Nothing,AbstractVector} = nothing") ==
        (name = "bias", type = "Union{Nothing,AbstractVector}", default = "nothing")
end

@testitem "split_sections on nested MD" tags = [:unit, :fast] begin
    using Markdown
    using DocumenterDocstringStyle: flatten, split_sections
    inner = md"""
    # Returns
    Nothing.
    """
    deeper = md"""
    ## Deeper
    Still returns.
    """
    outer = Markdown.MD(Any[md"    f(x)", md"Summary.", inner, deeper])
    pre, secs = split_sections(flatten(outer))
    @test length(pre) == 2
    @test first.(secs) == ["Returns"]
    @test length(last(secs[1])) == 3
end

@testitem "is_na" tags = [:unit, :fast] begin
    using Markdown
    using DocumenterDocstringStyle: is_na
    @test is_na(md"N/A".content, ["N/A"])
    @test is_na(md"  N/A  ".content, ["N/A"])
    @test !is_na(md"Not applicable.".content, ["N/A"])
    @test !is_na(md"N/A\n\nMore.".content, ["N/A"])
end

@testitem "first_sentence" tags = [:unit, :fast] begin
    using DocumenterDocstringStyle: first_sentence
    @test first_sentence("Sort the vector. Then more.") == ("Sort the vector.", false)
    @test first_sentence("Use e.g. Native code. Next.")[1] == "Use e.g. Native code."
    @test first_sentence(repeat("a", 250))[2]
end
