# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog],
and this project adheres to [Semantic Versioning].

## [Unreleased]

### Added

- Docstring schema checker with rules DS001–DS050, usable standalone through `check_module` and `check_docstring`.
- `SchemaConfig` Documenter plugin: fails or warns during `makedocs`, and does nothing without a config.
- `MINIMAL` and `NOSCHEMA` opt-out markers in the dependency-free `DocumenterDocstringStyleMarkers` package.
- Rendering themes `:labeled`, `:pydata`, `:numpydoc`, `:table`, `:rustdoc` and `:plain`, all defined as `ThemeSpec`s.
- Custom styles through `ThemeSpec`, TOML style files, design tokens and `register_theme!`.
- `@docstyle` block to switch the style per page, and `DocumenterDocstringStyle.preview`.
- Compatibility with DocumenterCodeBlocks.jl.

<!-- Links -->

[keep a changelog]: https://keepachangelog.com/en/1.1.0/
[semantic versioning]: https://semver.org/spec/v2.0.0.html

<!-- Versions -->

[unreleased]: https://github.com/langestefan/DocumenterDocstringStyle.jl/compare/v0.1.0...HEAD
