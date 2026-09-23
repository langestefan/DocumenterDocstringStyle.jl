"""
Documenter plugin that checks function docstrings against a fixed Markdown schema
and renders them in a structured layout.
"""
module DocumenterDocstringStyle

using Documenter: Documenter
using DocumenterDocstringStyleMarkers: MINIMAL, Minimal, NOSCHEMA, NoSchema
using Logging: Logging
using Markdown: Markdown
using MarkdownAST: MarkdownAST
using TOML: TOML

export MINIMAL, NOSCHEMA
export Problem, SchemaConfig, check_docstring, check_module
export DocstringTheme, ThemeSpec, register_theme!

include("config.jl")
include("problems.jl")
include("parse.jl")
include("methods.jl")
include("check.jl")
include("model.jl")
include("themes/interface.jl")
include("themes/spec.jl")
include("themes/tokens.jl")
include("themes/registry.jl")
include("themes/toml.jl")
include("themes/render.jl")
include("themes/builtins.jl")
include("transform.jl")
include("expander.jl")
include("pipeline.jl")
include("preview.jl")

end
