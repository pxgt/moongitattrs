# MoonGitAttrs

MoonGitAttrs is a pure MoonBit library and command-line tool for parsing,
evaluating, explaining, and auditing `.gitattributes` files.

The project is under active development for the September 2026 MoonBit
Hackathon. Its public API and command-line interface will stabilize at v0.1.0.

## Planned scope

- Parse Git attribute patterns and assignments with source-aware diagnostics.
- Match repository-relative paths with Git-style `*`, `?`, character classes,
  and `**` directory traversal.
- Resolve Set, Unset, Value, and Unspecified attribute states.
- Combine root and nested attribute files using Git-compatible precedence.
- Explain the rules that produced a path's final attributes.
- Audit common text, export, diff, merge, and Linguist policies.
- Render deterministic text, JSON, and Markdown reports.

The implementation follows the public behavior documented in
[Git Attributes](https://git-scm.com/docs/gitattributes). It is an independent
MoonBit implementation and does not copy Git source code.

## License

Apache-2.0.
