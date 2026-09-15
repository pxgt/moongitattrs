///|
fn state_label(state : AttributeState) -> String {
  match state {
    Set => "set"
    Unset => "unset"
    Value(value) => value
    Unspecified => "unspecified"
  }
}

///|
fn severity_label(severity : Severity) -> String {
  match severity {
    Info => "info"
    Warning => "warning"
    Error => "error"
  }
}

///|
fn sorted_attributes(
  attributes : Array[ResolvedAttribute],
) -> Array[ResolvedAttribute] {
  let result = attributes.copy()
  result.sort_by((left, right) => left.name.lexical_compare(right.name))
  result
}

///|
/// Renders an evaluation as compact, stable text suitable for terminals.
pub fn Evaluation::to_text(self : Evaluation) -> String {
  let output = StringBuilder()
  output.write_string("path: \{self.path}\n")
  let attributes = sorted_attributes(self.attributes)
  if attributes.length() == 0 {
    output.write_string("attributes: (none)\n")
  } else {
    output.write_string("attributes:\n")
    for attribute in attributes {
      output.write_string(
        "  \{attribute.name}: \{state_label(attribute.state)} " +
        "(\{attribute.source}:\{attribute.line}, \{attribute.pattern})\n",
      )
    }
  }
  output.to_string()
}

///|
/// Renders an evaluation as pretty JSON with attributes sorted by name.
pub fn Evaluation::to_json_string(self : Evaluation) -> String {
  let normalized : Evaluation = {
    path: self.path,
    attributes: sorted_attributes(self.attributes),
    matched_rules: self.matched_rules.copy(),
  }
  ToJson::to_json(normalized).stringify(indent=2)
}

///|
/// Renders diagnostics and policy findings as a Markdown table.
pub fn AuditReport::to_markdown(self : AuditReport) -> String {
  let output = StringBuilder()
  output.write_string("# MoonGitAttrs audit\n\n")
  if self.diagnostics.length() == 0 && self.findings.length() == 0 {
    output.write_string("No diagnostics or policy findings.\n")
    return output.to_string()
  }
  output.write_string("| Severity | Code | Source | Line | Message |\n")
  output.write_string("| --- | --- | --- | ---: | --- |\n")
  for item in self.diagnostics {
    output.write_string(
      "| \{severity_label(item.severity)} | \{item.code} | " +
      "\{item.source} | \{item.line} | \{item.message} |\n",
    )
  }
  for item in self.findings {
    output.write_string(
      "| \{severity_label(item.severity)} | \{item.code} | " +
      "\{item.source} | \{item.line} | \{item.message} |\n",
    )
  }
  output.to_string()
}

///|
/// Renders an audit report as pretty JSON.
pub fn AuditReport::to_json_string(self : AuditReport) -> String {
  ToJson::to_json(self).stringify(indent=2)
}
