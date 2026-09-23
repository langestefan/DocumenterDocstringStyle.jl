# Argument and keyword names of the methods a docstring documents. Uses the
# Base internals `method_argnames` and `kwarg_decl`; CI runs on LTS and latest.

# Methods whose signature is exactly the docstring's `sig`. `methods(f, sig)`
# returns every intersecting method, which can include a generic fallback with
# other argument names. Returns `(methods, exact)`; `exact` is `false` when
# nothing matched exactly and the intersecting set is used instead.
function documented_methods(f, sig)
    sig === Union{} && return collect(methods(f)), true
    body = Base.unwrap_unionall(sig)
    # Docstrings of methods with type parameters store their signature as
    # `Union{Tuple{T...}, Tuple{args...}} where T`; the second part holds the args.
    body isa Union && (body = body.b)
    argsig = Base.rewrap_unionall(body, sig)
    candidates = try
        collect(methods(f, argsig))
    catch
        Method[]
    end
    body isa DataType && body <: Tuple || return candidates, false
    target = Base.rewrap_unionall(Tuple{typeof(f), body.parameters...}, sig)
    exact = filter(m -> m.sig == target, candidates)
    return isempty(exact) ? (candidates, false) : (exact, true)
end

function clean_names(names)
    out = String[]
    for s in names
        name = replace(string(s), "..." => "")
        if !isempty(name) && !startswith(name, '#') && !any(==(name), out)
            push!(out, name)
        end
    end
    return out
end

# Positional and keyword names, and whether they come from an exact match.
function method_args(f, sig)
    ms, exact = documented_methods(f, sig)
    pos = reduce(vcat, (Base.method_argnames(m)[2:end] for m in ms); init = Symbol[])
    kws = reduce(vcat, (Base.kwarg_decl(m) for m in ms); init = Symbol[])
    if f isa Function && startswith(string(nameof(f)), '@')
        filter!(s -> !(s in (:__source__, :__module__)), pos)
    end
    return clean_names(pos), clean_names(kws), exact
end
