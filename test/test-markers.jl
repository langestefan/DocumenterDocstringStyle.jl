@testitem "Markers render as nothing" tags = [:unit, :fast] begin
    using DocumenterDocstringStyle: MINIMAL, NOSCHEMA
    module MarkerDocs
    using DocumenterDocstringStyle: MINIMAL, NOSCHEMA
    """
        f(x)

    Return `x`.

    $(MINIMAL)
    """
    f(x) = x
    """
        g(x)

    Return `x`.

    $(NOSCHEMA)
    """
    g(x) = x
    end
    for f in (MarkerDocs.f, MarkerDocs.g)
        text = sprint(show, MIME"text/plain"(), Base.Docs.doc(f))
        @test occursin("Return", text)
        @test !occursin("Minimal", text)
        @test !occursin("NoSchema", text)
    end
end
