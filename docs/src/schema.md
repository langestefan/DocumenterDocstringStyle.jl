# [Docstring schema](@id schema)

The schema applies to function docstrings. Types, constants and modules pass through unchecked.

## Sections

A full docstring has a header, made of an indented signature block followed by a summary paragraph, and then level-1 sections in this order. Only `#` headings start a section; deeper headings are fine inside one.

| Order | Section | Required | Body |
| :--- | :--- | :--- | :--- |
| 0 | Signature | Always | Indented code block, the first block of the docstring. `$(TYPEDSIGNATURES)` from DocStringExtensions works. Should end with `-> ReturnType`. |
| 0 | Summary | Always | One paragraph right after the signature. The first sentence ends with a period and stays under 200 characters. More paragraphs may follow. |
| 1 | Arguments | If a method has positional arguments | Bullet list, one item per argument. |
| 2 | Keywords | If a method has keyword arguments | Bullet list, same item format. |
| 3 | Returns | Always | Paragraph or single bullet. |
| 4 | Throws | Optional | Bullet list, one item per exception: the type in a code span, then the condition. |
| 5 | Notes | Optional | Free Markdown. Admonitions belong here. |
| 6 | Examples | Always | At least one `jldoctest` block. |
| 7 | See also | Optional | Paragraph of `@ref` links. |
| 8 | References | Optional | Bullet list of sources, one per item. Works with [DocumenterCitations.jl](https://github.com/JuliaDocs/DocumenterCitations.jl) `@cite` links, see [References and citations](@ref). |
| 9 | Extended help | Optional | Free Markdown. Must stay last: the REPL shows it only with `??f`. |

Section names match exactly and are case-sensitive. The list, the order and the required sections come from [`SchemaConfig`](@ref), so a project can rename or extend them.

## Parameter items

`# Arguments` and `# Keywords` items start with an inline code span; everything after it is the description:

```markdown
- `name::Type = default`: description, which may wrap onto
  indented continuation lines.
```

- Inside the code span, `name` is required. `::Type` and `= default` are optional, in that order.
- Varargs are written `args...` or `kwargs...`.
- Write one item per name; shared descriptions are not supported.

## References and citations

`# References` lists the sources of a docstring. It follows the convention of [DocumenterCitations.jl](https://github.com/JuliaDocs/DocumenterCitations.jl): one bullet per source, each a `@cite` link followed by a short citation, so the docstring still reads well in the REPL.

```markdown
# References
- [DumoulinVisin2016](@cite) V. Dumoulin and F. Visin. *A guide to convolution
  arithmetic for deep learning*. arXiv:1603.07285 (2016).
```

Add `CitationBibliography("refs.bib")` to the `plugins` of `makedocs`, next to `SchemaConfig`, and put an `@bibliography` block on one page. DocumenterCitations expands the links before the docstrings are rendered, so every style shows the resolved citations. See [`conv2d`](@ref Main.ConvDemo.conv2d) on the style pages and the [Bibliography](bibliography.md).

## Opting out

Every opt-out is explicit and visible in the source.

| Level | How | Effect |
| :--- | :--- | :--- |
| Section | Write `N/A` as the whole body of a section | The section counts as present |
| Docstring | Interpolate `$(MINIMAL)`, usually on the last line | Only the signature and summary are checked |
| Docstring | Interpolate `$(NOSCHEMA)` | Nothing is checked |
| Build | `SchemaConfig(exclude = [MyPkg.f])` | The listed functions are skipped |

The markers render as nothing, in the REPL and in HTML. Import them with `using DocumenterDocstringStyleMarkers: MINIMAL, NOSCHEMA`. `NOSCHEMA` wins over `MINIMAL`, and `exclude` wins over both.

## Rules

Every problem has a stable code. Suppress a rule for the whole build with `SchemaConfig(ignore = [:DS003])`.

| Code | Checks | Severity |
| :--- | :--- | :--- |
| DS001 | The docstring starts with a signature block | error |
| DS002 | A summary paragraph follows the signature | error |
| DS003 | The summary's first sentence ends with a period and stays under 200 characters | warning |
| DS010 | Every section name is known | error |
| DS011 | No section appears twice | error |
| DS012 | Sections follow the canonical order | error |
| DS020 | Required sections are present | error |
| DS030 | Every positional argument is documented | error |
| DS031 | Every documented argument exists | error |
| DS032 | Every keyword is documented | error |
| DS033 | Every documented keyword exists | error |
| DS034 | Each Arguments or Keywords item starts with a code span | error |
| DS040 | Examples contain a `jldoctest` block | error |
| DS050 | Not both `MINIMAL` and `NOSCHEMA` | warning |

DS030 and DS031 become warnings when the documented methods can't be matched exactly, for example when a generic fallback with other argument names intersects the signature. The 200-character limit in DS003 matches the tooltip brief of DocumenterCodeBlocks.
