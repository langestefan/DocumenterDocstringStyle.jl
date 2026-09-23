# Flatten nested `Markdown.MD` nodes into one list of blocks.
flatten(x) = x isa Markdown.MD ? reduce(vcat, map(flatten, x.content); init = Any[]) : Any[x]

inline_string(x) = sprint(Markdown.plaininline, x)

# Split blocks at level-1 headers into a preamble and `name => blocks` sections.
function split_sections(blocks)
    pre = Any[]
    secs = Pair{String, Vector{Any}}[]
    for b in blocks
        if b isa Markdown.Header{1}
            push!(secs, String(strip(inline_string(b.text))) => Any[])
        else
            push!(isempty(secs) ? pre : last(secs).second, b)
        end
    end
    return pre, secs
end

# A section is an explicit opt-out when its whole body is one N/A paragraph.
function is_na(blocks, markers)
    length(blocks) == 1 && blocks[1] isa Markdown.Paragraph || return false
    return strip(inline_string(blocks[1].content)) in markers
end

# Parse the code span of a parameter item, `name::Type = default`, into
# `(name, type, default)` with `nothing` for missing parts. `::` and `=` only
# count outside brackets, and `=` only when it is not part of `==`, `=>`, `<=`,
# `>=` or `!=`.
function parse_param_item(code::AbstractString)
    depth = 0
    colons = nothing
    equals = nothing
    chars = collect(code)
    n = length(chars)
    for i in 1:n
        c = chars[i]
        if c in ('(', '[', '{')
            depth += 1
        elseif c in (')', ']', '}')
            depth -= 1
        elseif depth == 0
            if c == ':' && i < n && chars[i + 1] == ':' && colons === nothing && equals === nothing
                colons = i
            elseif c == '=' && equals === nothing
                prev = i > 1 ? chars[i - 1] : ' '
                next = i < n ? chars[i + 1] : ' '
                if !(prev in ('=', '<', '>', '!')) && !(next in ('=', '>'))
                    equals = i
                end
            end
        end
    end
    head = equals === nothing ? chars : chars[1:(equals - 1)]
    default = equals === nothing ? nothing : strip(String(chars[(equals + 1):end]))
    if colons === nothing
        name = strip(String(head))
        type = nothing
    else
        name = strip(String(head[1:(colons - 1)]))
        type = strip(String(head[(colons + 2):end]))
    end
    nonempty(s) = s === nothing || isempty(s) ? nothing : String(s)
    return (name = String(name), type = nonempty(type), default = nonempty(default))
end

# Plain text of inline Markdown content, plus the ranges of code spans in it.
function plain_text(content)
    io = IOBuffer()
    spans = UnitRange{Int}[]
    plain_text!(io, content, spans)
    return String(take!(io)), spans
end

function plain_text!(io, x, spans)
    if x isa AbstractString
        print(io, x)
    elseif x isa Markdown.Code
        start = position(io) + 1
        print(io, x.code)
        push!(spans, start:position(io))
    elseif x isa AbstractVector
        foreach(y -> plain_text!(io, y, spans), x)
    elseif hasproperty(x, :text)
        plain_text!(io, x.text, spans)
    else
        Markdown.plaininline(io, x)
    end
    return
end

# Abbreviations whose trailing `.` does not end a sentence.
const ABBREVIATION_RE = r"(?:\b(?:e\.g|i\.e|etc|vs|cf|resp|approx|ca|viz|incl|meas|dist|est)|\bet\s+al|\bw\.r\.t|\ba\.k\.a|\bs\.t)\.$"i

# First sentence of `text`, capped at 200 characters, and whether the cap cut it
# off. Mirrors DocumenterCodeBlocks' tooltip brief so both plugins agree.
function first_sentence(text, code_spans = UnitRange{Int}[])
    incode(i) = any(r -> i in r, code_spans)
    lastidx = lastindex(text)
    stop = 0
    nchars = 0
    i = firstindex(text)
    while i <= lastidx && nchars < 200
        nchars += 1
        c = text[i]
        if (c === '.' || c === '!' || c === '?') && !incode(i)
            k = nextind(text, i)
            wasspace = k > lastidx || isspace(text[k])
            while k <= lastidx && isspace(text[k])
                k = nextind(text, k)
            end
            if !wasspace
                # punctuation inside a word, e.g. `1.5`
            elseif k > lastidx
                stop = i
                break
            elseif islowercase(text[k]) && !incode(k)
                # lowercase prose follows: the sentence continues
            elseif c === '.' && occursin(ABBREVIATION_RE, SubString(text, firstindex(text), i))
                # known abbreviation: the sentence continues
            else
                stop = i
                break
            end
        end
        i = nextind(text, i)
    end
    clipped = stop == 0 && length(text) > 200
    s = stop == 0 ? first(text, 200) : text[begin:stop]
    return String(strip(replace(s, r"\s+" => " "))), clipped
end
