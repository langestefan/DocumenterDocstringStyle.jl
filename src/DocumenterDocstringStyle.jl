"""
Documenter plugin that checks function docstrings against a fixed Markdown schema
and renders them in a structured layout.
"""
module DocumenterDocstringStyle

using Documenter: Documenter
using DocumenterDocstringStyleMarkers: MINIMAL, Minimal, NOSCHEMA, NoSchema
using Markdown: Markdown

export MINIMAL, NOSCHEMA
export Problem, SchemaConfig, check_docstring, check_module

include("config.jl")
include("problems.jl")
include("parse.jl")
include("methods.jl")
include("check.jl")
include("pipeline.jl")

end
