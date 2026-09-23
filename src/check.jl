struct CheckContext
    binding::Base.Docs.Binding
    sig::Any
    config::SchemaConfig
    path::String
    line::Int
    problems::Vector{Problem}
end

function report!(ctx::CheckContext, code::Symbol, message; severity = RULES[code])
    code in ctx.config.ignore && return
    push!(ctx.problems, Problem(code, severity, ctx.binding, ctx.sig, ctx.path, ctx.line, message))
    return
end

"""
    check_module(mod::Module; config::SchemaConfig = SchemaConfig()) -> Vector{Problem}

Check every function docstring in `mod` against the schema.

Types, constants and modules are skipped, as are bindings listed in
`config.exclude`.

# Arguments
- `mod::Module`: the module whose docstrings to check.

# Keywords
- `config::SchemaConfig = SchemaConfig()`: schema and rule settings.

# Returns
The problems found, sorted by file and line.

# Examples
```jldoctest
julia> using DocumenterDocstringStyle

julia> module Empty end;

julia> check_module(Empty)
DocumenterDocstringStyle: 0 problem(s)
```
"""
function check_module(mod::Module; config::SchemaConfig = SchemaConfig())
    problems = Problem[]
    for (binding, multidoc) in Base.Docs.meta(mod)
        isdefined(binding.mod, binding.var) || continue
        f = Base.Docs.resolve(binding)
        f isa Function || continue
        is_excluded(config, binding, f) && continue
        for (sig, ds) in multidoc.docs
            append!(problems, check_docstring(ds, binding, sig; config))
        end
    end
    sort!(problems; by = p -> (p.path, p.line, string(p.binding), p.code))
    return problems
end

is_excluded(config, binding, f) = any(e -> isequal(e, binding) || e === f, config.exclude)

"""
    check_docstring(ds::Base.Docs.DocStr, binding, sig; config::SchemaConfig = SchemaConfig()) -> Vector{Problem}

Check one docstring against the schema.

# Arguments
- `ds::Base.Docs.DocStr`: the docstring, as stored in `Base.Docs.meta(mod)`.
- `binding`: the documented `Base.Docs.Binding`.
- `sig`: the docstring's signature type, `Union{}` when it has none.

# Keywords
- `config::SchemaConfig = SchemaConfig()`: schema and rule settings.

# Returns
The problems found, in rule order.

# Examples
```jldoctest
julia> using DocumenterDocstringStyle

julia> module M
           "No signature block."
           f(x) = x
       end;

julia> b = Base.Docs.Binding(M, :f);

julia> ds = Base.Docs.meta(M)[b].docs[Tuple{Any}];

julia> [p.code for p in check_docstring(ds, b, Tuple{Any})]
5-element Vector{Symbol}:
 :DS001
 :DS002
 :DS020
 :DS020
 :DS020
```
"""
function check_docstring(ds::Base.Docs.DocStr, binding, sig; config::SchemaConfig = SchemaConfig())
    ctx = CheckContext(binding, sig, config, docstring_path(ds, binding), get(ds.data, :linenumber, 0), Problem[])
    f = isdefined(binding.mod, binding.var) ? Base.Docs.resolve(binding) : nothing
    f isa Function || return ctx.problems

    minimal = any(x -> x isa Minimal, ds.text)
    noschema = any(x -> x isa NoSchema, ds.text)
    minimal && noschema && report!(ctx, :DS050, "both MINIMAL and NOSCHEMA present, using NOSCHEMA")
    noschema && return ctx.problems

    pre, secs = split_sections(flatten(Base.Docs.parsedoc(ds)))
    rule_header!(ctx, pre)
    minimal && return ctx.problems

    rule_sections!(ctx, secs)
    pos, kws, exact = method_args(f, sig)
    rule_required!(ctx, secs, pos, kws)
    body = Dict(secs)
    rule_names!(ctx, body, "Arguments", pos, :DS030, :DS031, exact)
    rule_names!(ctx, body, "Keywords", kws, :DS032, :DS033, true)
    rule_examples!(ctx, body)
    return ctx.problems
end

function docstring_path(ds, binding)
    path = string(get(ds.data, :path, "?"))
    root = pkgdir(binding.mod)
    root === nothing && return path
    rel = relpath(path, root)
    return startswith(rel, "..") ? path : rel
end

# DS001-DS003: signature block, summary paragraph and its first sentence.
function rule_header!(ctx, pre)
    if !(length(pre) >= 1 && pre[1] isa Markdown.Code)
        report!(ctx, :DS001, "must start with an indented signature block")
    end
    if !(length(pre) >= 2 && pre[2] isa Markdown.Paragraph)
        report!(ctx, :DS002, "missing summary paragraph after the signature")
        return
    end
    sentence, clipped = first_sentence(plain_text(pre[2].content)...)
    if clipped || !endswith(sentence, '.')
        report!(ctx, :DS003, "summary's first sentence should end in a period and stay under 200 characters")
    end
    return
end

# DS010-DS012: unknown, duplicate and misordered sections.
function rule_sections!(ctx, secs)
    order = ctx.config.order
    names = first.(secs)
    for n in names
        n in order || report!(ctx, :DS010, "unknown section `# $n`")
    end
    for n in unique(names)
        count(==(n), names) > 1 && report!(ctx, :DS011, "duplicate section `# $n`")
    end
    known = filter(in(order), unique(names))
    if !issorted(known; by = n -> findfirst(==(n), order))
        expected = filter(in(known), order)
        report!(ctx, :DS012, "sections out of order, expected: $(join(expected, ", "))")
    end
    return
end

# DS020: required sections, partly derived from the documented methods.
function rule_required!(ctx, secs, pos, kws)
    required = copy(ctx.config.required)
    isempty(pos) || push!(required, "Arguments")
    isempty(kws) || push!(required, "Keywords")
    order = ctx.config.order
    sort!(required; by = n -> something(findfirst(==(n), order), length(order) + 1))
    names = first.(secs)
    for r in required
        r in names || report!(ctx, :DS020, "missing `# $r` (write `N/A` in it to opt out)")
    end
    return
end

# DS030-DS034: documented names match the real argument or keyword names.
function rule_names!(ctx, body, section, actual, missing_code, unknown_code, exact)
    blocks = get(body, section, nothing)
    (blocks === nothing || is_na(blocks, ctx.config.na_markers)) && return
    documented = String[]
    item = 0
    for b in blocks
        b isa Markdown.List || continue
        for it in b.items
            item += 1
            name = item_name(it)
            if name === nothing
                report!(ctx, :DS034, "item $item of `# $section` must start with `` `name` ``")
            else
                push!(documented, name)
            end
        end
    end
    missing_names = setdiff(actual, documented)
    unknown = setdiff(documented, actual)
    # A malformed item most likely documents one of the missing names.
    if !isempty(missing_names) && length(documented) == item
        report!(ctx, missing_code, "`# $section` misses: $(join(missing_names, ", "))"; severity = exact ? RULES[missing_code] : :warn)
    end
    if !isempty(unknown)
        report!(ctx, unknown_code, "`# $section` lists unknown names: $(join(unknown, ", "))"; severity = exact ? RULES[unknown_code] : :warn)
    end
    return
end

# Name in the leading code span of a list item, or `nothing`.
function item_name(item)
    isempty(item) && return nothing
    para = first(item)
    para isa Markdown.Paragraph && !isempty(para.content) || return nothing
    c = first(para.content)
    c isa Markdown.Code || return nothing
    name = replace(parse_param_item(c.code).name, "..." => "")
    return isempty(name) ? nothing : name
end

# DS040: Examples must contain a doctest.
function rule_examples!(ctx, body)
    blocks = get(body, "Examples", nothing)
    (blocks === nothing || is_na(blocks, ctx.config.na_markers)) && return
    if !any(b -> b isa Markdown.Code && startswith(b.language, "jldoctest"), blocks)
        report!(ctx, :DS040, "`# Examples` needs at least one jldoctest block")
    end
    return
end
