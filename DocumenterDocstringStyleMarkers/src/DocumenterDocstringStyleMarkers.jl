"""
Opt-out markers for DocumenterDocstringStyle.jl.

Interpolate `\$(MINIMAL)` or `\$(NOSCHEMA)` into a docstring to relax the schema
check for it. The markers render as nothing in the REPL and in HTML, but stay
visible to the checker because docstring interpolation is lazy: the objects are
kept unformatted in `Base.Docs.DocStr.text`.

This package has no dependencies, so packages under documentation can depend on
it without pulling in Documenter.
"""
module DocumenterDocstringStyleMarkers

export MINIMAL, NOSCHEMA

"""
    SchemaMarker

Supertype of the docstring opt-out markers.
"""
abstract type SchemaMarker end

"""
    Minimal <: SchemaMarker

Marker type behind [`MINIMAL`](@ref).
"""
struct Minimal <: SchemaMarker end

"""
    NoSchema <: SchemaMarker

Marker type behind [`NOSCHEMA`](@ref).
"""
struct NoSchema <: SchemaMarker end

"""
    MINIMAL

Interpolate into a docstring to check only its signature and summary.
"""
const MINIMAL = Minimal()

"""
    NOSCHEMA

Interpolate into a docstring to skip all schema checks for it.
"""
const NOSCHEMA = NoSchema()

Base.Docs.formatdoc(::IO, ::Base.Docs.DocStr, ::SchemaMarker) = nothing

end
