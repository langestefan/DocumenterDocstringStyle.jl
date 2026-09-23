# DocumenterDocstringStyle.jl

[![Stable Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://langestefan.github.io/DocumenterDocstringStyle.jl/stable)
[![Development documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://langestefan.github.io/DocumenterDocstringStyle.jl/dev)

[![Test workflow status](https://github.com/langestefan/DocumenterDocstringStyle.jl/actions/workflows/Test.yml/badge.svg?branch=main)](https://github.com/langestefan/DocumenterDocstringStyle.jl/actions/workflows/Test.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/langestefan/DocumenterDocstringStyle.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/langestefan/DocumenterDocstringStyle.jl)
[![Lint workflow Status](https://github.com/langestefan/DocumenterDocstringStyle.jl/actions/workflows/Lint.yml/badge.svg?branch=main)](https://github.com/langestefan/DocumenterDocstringStyle.jl/actions/workflows/Lint.yml?query=branch%3Amain)
[![Docs workflow Status](https://github.com/langestefan/DocumenterDocstringStyle.jl/actions/workflows/Docs.yml/badge.svg?branch=main)](https://github.com/langestefan/DocumenterDocstringStyle.jl/actions/workflows/Docs.yml?query=branch%3Amain)

A [Documenter.jl](https://documenter.juliadocs.org/) plugin that checks function
docstrings against a fixed Markdown schema and renders them in a clear, structured
layout.

## Usage

Pass a `SchemaConfig` to `makedocs`:

```julia
using Documenter, DocumenterDocstringStyle, MyPkg

makedocs(;
    modules = [MyPkg],
    sitename = "MyPkg.jl",
    plugins = [SchemaConfig(strict = true, theme = :pydata)],
)
```

- The build fails (or warns, with `strict = false`) when a docstring breaks the schema, with one line per problem.
- `theme` picks a built-in style (`:labeled`, `:pydata`, `:numpydoc`, `:table`, `:rustdoc`, `:plain`), a `ThemeSpec` or a TOML style file.
- It works alongside [DocumenterCodeBlocks.jl](https://github.com/fredrikekre/DocumenterCodeBlocks.jl).
- `check_module(MyPkg)` runs the same check in a test suite.

See the [documentation](https://langestefan.github.io/DocumenterDocstringStyle.jl/dev/) for the schema, every style and how to write your own.

## How to Cite

If you use DocumenterDocstringStyle.jl in your work, please cite using the reference given in [CITATION.cff](https://github.com/langestefan/DocumenterDocstringStyle.jl/blob/main/CITATION.cff).

## Contributing

If you want to make contributions of any kind, please first that a look into our [contributing guide directly on GitHub](docs/src/contributing.md) or the [contributing page on the website](https://langestefan.github.io/DocumenterDocstringStyle.jl/dev/contributing/)
