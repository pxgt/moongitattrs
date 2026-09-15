///|
fn finding(
  code : String,
  severity : Severity,
  message : String,
  rule : Rule,
  attribute? : String? = None,
) -> Finding {
  {
    code,
    severity,
    message,
    source: rule.source,
    line: rule.line,
    pattern: rule.pattern,
    attribute,
  }
}

///|
fn audit_duplicate_assignments(rule : Rule, findings : Array[Finding]) -> Unit {
  let seen : Map[String, Unit] = Map([])
  for assignment in rule.assignments {
    if seen.contains(assignment.name) {
      findings.push(
        finding(
          "MGA101",
          Warning,
          "attribute '\{assignment.name}' is assigned more than once in one rule",
          rule,
          attribute=Some(assignment.name),
        ),
      )
    }
    seen[assignment.name] = ()
  }
}

///|
fn audit_reserved_names(rule : Rule, findings : Array[Finding]) -> Unit {
  for assignment in rule.assignments {
    if assignment.name.has_prefix("builtin_") {
      findings.push(
        finding(
          "MGA102",
          Error,
          "the builtin_* namespace is reserved by Git",
          rule,
          attribute=Some(assignment.name),
        ),
      )
    }
  }
}

///|
fn audit_eol_values(rule : Rule, findings : Array[Finding]) -> Unit {
  for assignment in rule.assignments {
    if assignment.name == "eol" {
      match assignment.state {
        Value("lf") | Value("crlf") => ()
        Value(value) =>
          findings.push(
            finding(
              "MGA103",
              Error,
              "eol only accepts 'lf' or 'crlf', not '\{value}'",
              rule,
              attribute=Some("eol"),
            ),
          )
        _ =>
          findings.push(
            finding(
              "MGA104",
              Warning,
              "eol is normally written as eol=lf or eol=crlf",
              rule,
              attribute=Some("eol"),
            ),
          )
      }
    }
  }
}

///|
fn audit_macro_usage(
  rule : Rule,
  macros : Array[MacroDefinition],
  findings : Array[Finding],
) -> Unit {
  for assignment in rule.assignments {
    let is_macro = assignment.name == "binary" ||
      macros.any(definition => definition.name == assignment.name)
    if is_macro && assignment.state != Set {
      findings.push(
        finding(
          "MGA105",
          Warning,
          "attribute macros expand only when set without a value",
          rule,
          attribute=Some(assignment.name),
        ),
      )
    }
  }
}

///|
fn audit_text_conflicts(rule : Rule, findings : Array[Finding]) -> Unit {
  let mut has_binary = false
  let mut has_text_override = false
  for assignment in rule.assignments {
    if assignment.name == "binary" && assignment.state == Set {
      has_binary = true
    }
    if assignment.name == "text" && assignment.state != Unset {
      has_text_override = true
    }
  }
  if has_binary && has_text_override {
    findings.push(
      finding(
        "MGA106",
        Warning,
        "binary expands to -text, but this rule also assigns text",
        rule,
        attribute=Some("text"),
      ),
    )
  }
}

///|
/// Audits parsed rules for common configuration mistakes and ambiguous intent.
pub fn RuleSet::audit(self : RuleSet) -> AuditReport {
  let findings : Array[Finding] = []
  for rule in self.rules {
    audit_duplicate_assignments(rule, findings)
    audit_reserved_names(rule, findings)
    audit_eol_values(rule, findings)
    audit_macro_usage(rule, self.macros, findings)
    audit_text_conflicts(rule, findings)
  }
  { diagnostics: self.diagnostics.copy(), findings, }
}

///|
/// Returns true when parsing or policy auditing found an error.
pub fn AuditReport::has_errors(self : AuditReport) -> Bool {
  self.diagnostics.any(item => item.severity == Error) ||
  self.findings.any(item => item.severity == Error)
}
