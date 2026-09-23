# Documenter pipeline steps. Each one is a no-op unless the user passed a
# `SchemaConfig` in `makedocs(plugins = [...])`. `Documenter.getplugin` would
# construct a default config, so check `doc.plugins` directly.

function schema_config(doc::Documenter.Document)
    haskey(doc.plugins, SchemaConfig) || return nothing
    return doc.plugins[SchemaConfig]::SchemaConfig
end

# Runs the schema check after Documenter's own CheckDocument (4.0).
abstract type CheckSchema <: Documenter.Builder.DocumentPipeline end

Documenter.Selectors.order(::Type{CheckSchema}) = 4.1

function Documenter.Selectors.runner(::Type{CheckSchema}, doc::Documenter.Document)
    config = schema_config(doc)
    config === nothing && return
    @info "CheckSchema: checking docstrings against the schema."
    problems = Problem[]
    for mod in doc.blueprint.modules
        append!(problems, check_module(mod; config))
    end
    isempty(problems) && return
    report = sprint(show, MIME"text/plain"(), problems)
    if config.strict && any(p -> p.severity === :error, problems)
        error(report)
    end
    @warn report
    return
end
