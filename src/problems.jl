# Rule codes and their default severity. DS030/DS031 drop to warnings when
# method filtering has to fall back to intersecting methods.
const RULES = Dict{Symbol, Symbol}(
    :DS001 => :error,
    :DS002 => :error,
    :DS003 => :warn,
    :DS010 => :error,
    :DS011 => :error,
    :DS012 => :error,
    :DS020 => :error,
    :DS030 => :error,
    :DS031 => :error,
    :DS032 => :error,
    :DS033 => :error,
    :DS034 => :error,
    :DS040 => :error,
    :DS050 => :warn,
)

"""
    Problem

One schema violation found in a docstring.

# Fields
- `code::Symbol`: rule code, e.g. `:DS020`.
- `severity::Symbol`: `:error` or `:warn`.
- `binding::Base.Docs.Binding`: the documented binding.
- `sig`: the docstring's signature type (`Union{}` when it has none).
- `path::String`: source file, relative to the package root when known.
- `line::Int`: line of the docstring in `path`, `0` when unknown.
- `message::String`: human-readable description.
"""
struct Problem
    code::Symbol
    severity::Symbol
    binding::Base.Docs.Binding
    sig::Any
    path::String
    line::Int
    message::String
end

function location_string(p::Problem)
    sig = p.sig === Union{} ? "" : " $(p.sig)"
    return string(p.binding, sig, " (", p.path, ":", p.line, ")")
end

function Base.show(io::IO, ::MIME"text/plain", problems::Vector{Problem})
    print(io, "DocumenterDocstringStyle: ", length(problems), " problem(s)")
    last = nothing
    for p in problems
        loc = location_string(p)
        if loc != last
            print(io, "\n  ", loc)
            last = loc
        end
        print(io, "\n    ", p.code, " ", p.message)
    end
    return
end
