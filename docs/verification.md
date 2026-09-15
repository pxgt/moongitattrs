# Verification

MoonGitAttrs is verified with MoonBit stable `0.1.20260904` and compiler
`v0.10.12+1634b282e` (2026-09-07). The reusable package is checked and tested on
`wasm`, `wasm-gc`, `js` and `native`; the file-reading CLI is native-only.

## Reproduce locally

Run from the repository root:

```bash
moon fmt --check
moon info --target all
git diff --exit-code
moon check --target all --deny-warn --warn-list +73
moon build --target all
moon test --target all --deny-warn --warn-list +73
moon run cmd/main
moon run cmd/main -- explain examples/sample.gitattributes README.md
moon run cmd/main -- explain-json examples/sample.gitattributes README.md
moon run cmd/main -- audit examples/sample.gitattributes
moon run cmd/main -- match "docs/**" "docs/guide.md"
moon package --frozen
```

The test suite covers assignment grammar, source diagnostics, basename and
directory matching, double-star traversal, nested source precedence, macro
expansion, per-attribute overrides, policy findings and stable report output.

## Differential check against Git

For additional maintenance checks, create a temporary repository containing the
same rules and compare selected paths with:

```bash
git check-attr --all -- README.md
```

The automated tests keep equivalent expected states in MoonBit so CI does not
depend on the host Git version.
