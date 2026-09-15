///|
/// Creates a portable attribute source. `base_dir` is repository-relative and
/// is empty for root, global, system, and `$GIT_DIR/info/attributes` files.
pub fn AttributeSource::new(
  source : String,
  content : String,
  base_dir? : String = "",
) -> AttributeSource {
  { source, base_dir, content, }
}

///|
/// Parses multiple sources in ascending precedence order.
///
/// Pass system and global files first, followed by root and progressively
/// deeper `.gitattributes` files. Pass `$GIT_DIR/info/attributes` last when it
/// is available. Later matching assignments override earlier ones per
/// attribute, matching Git's precedence model.
pub fn parse_sources(sources : ArrayView[AttributeSource]) -> RuleSet {
  let rules : Array[Rule] = []
  let macros : Array[MacroDefinition] = []
  let diagnostics : Array[Diagnostic] = []
  for source in sources {
    let parsed = parse(
      source.content,
      source=source.source,
      base_dir=source.base_dir,
    )
    rules.append(parsed.rules)
    macros.append(parsed.macros)
    diagnostics.append(parsed.diagnostics)
  }
  { rules, macros, diagnostics, }
}

///|
/// Returns all matching rules in evaluation order for inspection and tooling.
pub fn RuleSet::matching_rules(self : RuleSet, path : String) -> Array[Rule] {
  self.rules.filter(rule => {
    match_pattern(rule.pattern, path, base_dir=rule.base_dir)
  })
}
