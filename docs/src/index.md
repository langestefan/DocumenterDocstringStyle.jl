```@meta
CurrentModule = DocumenterDocstringStyle
```

# Home

## DocumenterDocstringStyle.jl

[![Stable Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://langestefan.github.io/DocumenterDocstringStyle.jl/stable)
[![Development documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://langestefan.github.io/DocumenterDocstringStyle.jl/dev)

[![Test workflow status](https://github.com/langestefan/DocumenterDocstringStyle.jl/actions/workflows/Test.yml/badge.svg?branch=main)](https://github.com/langestefan/DocumenterDocstringStyle.jl/actions/workflows/Test.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/langestefan/DocumenterDocstringStyle.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/langestefan/DocumenterDocstringStyle.jl)
[![Lint workflow Status](https://github.com/langestefan/DocumenterDocstringStyle.jl/actions/workflows/Lint.yml/badge.svg?branch=main)](https://github.com/langestefan/DocumenterDocstringStyle.jl/actions/workflows/Lint.yml?query=branch%3Amain)
[![Docs workflow Status](https://github.com/langestefan/DocumenterDocstringStyle.jl/actions/workflows/Docs.yml/badge.svg?branch=main)](https://github.com/langestefan/DocumenterDocstringStyle.jl/actions/workflows/Docs.yml?query=branch%3Amain)

A [Documenter.jl](https://documenter.juliadocs.org/) plugin that checks function docstrings against a fixed Markdown [schema](@ref schema) and renders them in a structured layout. One plain Markdown source can look like the [PyTorch](styles/pydata.md), [NumPy](styles/numpydoc.md), [mkdocstrings](styles/table.md) or [docs.rs](styles/rustdoc.md) docs, and still read well in the REPL.

```julia
makedocs(; modules = [MyPkg], plugins = [SchemaConfig(theme = :pydata)])
```

Start with [Getting started](getting-started.md).
