# Architecture

MoonGitAttrs separates parsing, matching, evaluation, auditing, and rendering.
The root package owns the public data model so consumers can inspect rules,
diagnostics, resolved attributes, and explanation traces without importing
implementation-only packages.

The intended data flow is:

```text
.gitattributes text -> parser -> ordered rules -> path matcher
                    -> evaluator -> resolved attributes + trace
                    -> auditor/renderers -> human or machine reports
```

## Boundaries

MoonGitAttrs evaluates attribute rules supplied by callers. It does not invoke
Git, mutate a working tree, apply line-ending conversion, run diff or merge
drivers, or decide how GitHub Linguist classifies a repository. File-system
discovery is kept in the CLI so the reusable library remains deterministic and
portable across MoonBit backends.

## Compatibility target

The library targets MoonBit's stable `wasm`, `wasm-gc`, `js`, and `native`
backends. Core parsing and evaluation have no network or file-system dependency.

## Module responsibilities

- `assignment.mbt` owns attribute-name validation and the four assignment forms.
- `parser.mbt` turns source text into ordered rules, macros and diagnostics.
- `pattern.mbt` contains the deterministic Git-style path matcher.
- `sources.mbt` composes already ordered configuration sources.
- `evaluator.mbt` applies matching rules and expands attribute macros.
- `audit.mbt` reports repository-policy risks without changing the rule result.
- `render.mbt` provides stable terminal, JSON and Markdown representations.
- `cmd/main` is the only package that reads files or exits with process codes.

## Precedence contract

`parse_sources` accepts sources from lowest to highest precedence. Within a source,
later matching lines override earlier lines one attribute at a time. A caller that
wants Git's complete precedence order should pass system attributes, global
attributes, root and successively deeper `.gitattributes` files, then
`.git/info/attributes`.

## Non-goals

- changing files, line endings or Git index state;
- launching Git or reproducing diff and merge drivers;
- discovering repository files automatically in the portable library;
- promising classification results for third-party services such as Linguist.

These boundaries keep the core deterministic and make it suitable for browser,
Wasm and native tooling. Future maintenance can add adapters without coupling the
rule engine to a particular file system.
