# TOML style files mirror ThemeSpec. Errors name the file, the key and the
# allowed values.

const TOML_KEYS = ("name", "extends", "section_header", "params", "default", "labels", "sections", "tokens", "tokens_dark", "css")
const TOML_TABLES = ("labels", "sections", "tokens", "tokens_dark")
const TOML_TOP_LEVEL = ("name", "extends", "section_header", "params", "default", "css")

toml_error(file, msg) = error("style file $file: $msg")

function toml_string(file, key, value)
    value isa String || toml_error(file, "`$key` must be a string, got `$(repr(value))`")
    return value
end

function toml_table(file, key, value)
    value isa AbstractDict || toml_error(file, "`$key` must be a table")
    for (k, v) in value
        # A top-level key written after a table header ends up inside that table.
        if key in TOML_TABLES && k in TOML_TOP_LEVEL && !(v isa AbstractDict)
            toml_error(file, "`$key.$k` looks like a top-level key placed after the `[$key]` table; move it above the first table")
        end
    end
    return value
end

function toml_layout(file, key, value)
    s = Symbol(toml_string(file, key, value))
    allowed = LAYOUT_FIELDS[Symbol(last(split(key, '.')))]
    s in allowed || toml_error(file, "unknown `$key` value \"$s\", allowed: $(join(map(a -> "\"$a\"", allowed), ", "))")
    return s
end

"""
    load_style(path::AbstractString) -> ThemeSpec

Read a TOML style file into a [`ThemeSpec`](@ref). Relative `css` paths are
resolved against the file's directory.

$(MINIMAL)
"""
function load_style(path::AbstractString)
    file = abspath(path)
    isfile(file) || error("style file $file not found")
    data = try
        TOML.parsefile(file)
    catch err
        toml_error(file, sprint(showerror, err))
    end
    for key in keys(data)
        key in TOML_KEYS || toml_error(file, "unknown key `$key`, allowed: $(join(TOML_KEYS, ", "))")
    end
    kwargs = Dict{Symbol, Any}()
    haskey(data, "name") && (kwargs[:name] = Symbol(toml_string(file, "name", data["name"])))
    if haskey(data, "extends")
        kwargs[:extends] = Symbol(toml_string(file, "extends", data["extends"]))
    end
    for field in ("section_header", "params", "default")
        haskey(data, field) && (kwargs[Symbol(field)] = toml_layout(file, field, data[field]))
    end
    if haskey(data, "labels")
        labels = toml_table(file, "labels", data["labels"])
        kwargs[:labels] = Dict(Symbol(k) => toml_string(file, "labels.$k", v) for (k, v) in labels)
    end
    if haskey(data, "sections")
        sections = Dict{Symbol, Dict{Symbol, Symbol}}()
        for (id, overrides) in toml_table(file, "sections", data["sections"])
            overrides isa AbstractDict || toml_error(file, "`sections.$id` must be a table")
            for k in keys(overrides)
                haskey(LAYOUT_FIELDS, Symbol(k)) ||
                    toml_error(file, "unknown key `sections.$id.$k`, allowed: $(join(keys(LAYOUT_FIELDS), ", "))")
            end
            sections[Symbol(id)] = Dict(Symbol(k) => toml_layout(file, "sections.$id.$k", v) for (k, v) in overrides)
        end
        kwargs[:sections] = sections
    end
    for field in ("tokens", "tokens_dark")
        haskey(data, field) || continue
        tokens = toml_table(file, field, data[field])
        for k in keys(tokens)
            k in TOKENS || toml_error(file, "unknown token `$field.$k`, allowed: $(join(TOKENS, ", "))")
        end
        kwargs[Symbol(field)] = Dict(k => toml_string(file, "$field.$k", v) for (k, v) in tokens)
    end
    if haskey(data, "css")
        css = data["css"]
        css isa AbstractVector || toml_error(file, "`css` must be an array of paths")
        paths = String[]
        for p in css
            full = normpath(joinpath(dirname(file), toml_string(file, "css", p)))
            isfile(full) || toml_error(file, "`css` entry \"$p\" not found at $full")
            push!(paths, full)
        end
        kwargs[:css] = paths
    end
    spec = ThemeSpec(; kwargs...)
    spec.extends === spec.name && toml_error(file, "cyclic `extends`: `$(spec.name)` extends itself")
    return spec
end
