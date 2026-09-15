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
