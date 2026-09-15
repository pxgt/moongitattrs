///|
fn built_in_binary_macro() -> MacroDefinition {
  {
    name: "binary",
    assignments: [
      { name: "diff", state: Unset, },
      { name: "merge", state: Unset, },
      { name: "text", state: Unset, },
    ],
    source: "<builtin>",
    line: 0,
  }
}

///|
fn find_macro(
  macros : Array[MacroDefinition],
  name : String,
) -> MacroDefinition? {
  for index = macros.length() - 1; index >= 0; index = index - 1 {
    if macros[index].name == name {
      return Some(macros[index])
    }
  }
  None
}

///|
fn resolve_macro(
  macros : Array[MacroDefinition],
  assignment : Assignment,
) -> Array[Assignment]? {
  guard assignment.state is Set else { return None }
  if assignment.name == "binary" {
    Some(built_in_binary_macro().assignments)
  } else {
    match find_macro(macros, assignment.name) {
      Some(definition) => Some(definition.assignments)
      None => None
    }
  }
}

///|
fn apply_assignment(
  assignment : Assignment,
  rule : Rule,
  rule_index : Int,
  macros : Array[MacroDefinition],
  resolved : Map[String, ResolvedAttribute],
  expansion_stack : Array[String],
) -> Unit {
  resolved[assignment.name] = {
    name: assignment.name,
    state: assignment.state,
    source: rule.source,
    line: rule.line,
    pattern: rule.pattern,
    rule_index,
  }
  guard resolve_macro(macros, assignment) is Some(expansion) else { return }
  if expansion_stack.contains(assignment.name) {
    return
  }
  let next_stack = expansion_stack.copy()
  next_stack.push(assignment.name)
  for nested in expansion {
    apply_assignment(nested, rule, rule_index, macros, resolved, next_stack)
  }
}

///|
/// Evaluates all matching rules for a repository-relative path.
pub fn RuleSet::evaluate(self : RuleSet, path : String) -> Evaluation {
  let resolved : Map[String, ResolvedAttribute] = Map([])
  let matched_rules : Array[Int] = []
  for index, rule in self.rules {
    if match_pattern(rule.pattern, path, base_dir=rule.base_dir) {
      matched_rules.push(index)
      for assignment in rule.assignments {
        apply_assignment(assignment, rule, index, self.macros, resolved, [])
      }
    }
  }
  { path, attributes: resolved.values().collect(), matched_rules, }
}

///|
/// Evaluates a batch of paths while preserving input order.
pub fn RuleSet::evaluate_many(
  self : RuleSet,
  paths : ArrayView[String],
) -> Array[Evaluation] {
  paths.map(path => self.evaluate(path))
}

///|
/// Returns the resolved state of `name`, or `Unspecified` when no rule decided it.
pub fn Evaluation::attribute(
  self : Evaluation,
  name : String,
) -> AttributeState {
  for attribute in self.attributes {
    if attribute.name == name {
      return attribute.state
    }
  }
  Unspecified
}
