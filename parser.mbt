///|
priv struct TokenizedLine {
  tokens : Array[String]
  unclosed_quote : Bool
  trailing_escape : Bool
}

///|
fn decode_escaped_char(char : Char) -> Char {
  match char {
    'n' => '\n'
    'r' => '\r'
    't' => '\t'
    'b' => '\b'
    _ => char
  }
}

///|
fn tokenize_line(line : String) -> TokenizedLine {
  let tokens : Array[String] = []
  let current = StringBuilder()
  let mut quoted = false
  let mut escaping = false
  let mut started = false
  for char in line {
    if escaping {
      current.write_char(decode_escaped_char(char))
      escaping = false
      started = true
    } else if char == '\\' {
      escaping = true
      started = true
    } else if char == '"' {
      quoted = !quoted
      started = true
    } else if !quoted && char.is_ascii_whitespace() {
      if started {
        tokens.push(current.to_string())
        current.reset()
        started = false
      }
    } else {
      current.write_char(char)
      started = true
    }
  }
  if escaping {
    current.write_char('\\')
  }
  if started {
    tokens.push(current.to_string())
  }
  { tokens, unclosed_quote: quoted, trailing_escape: escaping, }
}

///|
fn diagnostic(
  code : String,
  severity : Severity,
  message : String,
  source : String,
  line : Int,
  column? : Int = 1,
) -> Diagnostic {
  { code, severity, message, source, line, column, }
}

///|
fn normalized_line(line : StringView) -> String {
  let text = line.to_owned()
  if text.has_suffix("\r") {
    text.unsafe_substring(start=0, end=text.length() - 1)
  } else {
    text
  }
}

///|
fn parse_assignment_for_line(
  token : String,
  source : String,
  line : Int,
  diagnostics : Array[Diagnostic],
) -> Assignment? {
  try parse_assignment(token) catch {
    InvalidAssignment(_) => {
      diagnostics.push(
        diagnostic(
          "MGA004",
          Error,
          "invalid attribute assignment: \{token}",
          source,
          line,
        ),
      )
      None
    }
    InvalidAttributeName(name) => {
      diagnostics.push(
        diagnostic(
          "MGA003",
          Error,
          "invalid attribute name: \{name}",
          source,
          line,
        ),
      )
      None
    }
  } noraise {
    assignment => Some(assignment)
  }
}

///|
fn parse_line(
  text : String,
  source : String,
  base_dir : String,
  line : Int,
  rules : Array[Rule],
  macros : Array[MacroDefinition],
  diagnostics : Array[Diagnostic],
) -> Unit {
  let trimmed = text.trim_start()
  if trimmed.length() == 0 || trimmed.has_prefix("#") {
    return
  }
  let tokenized = tokenize_line(text)
  if tokenized.unclosed_quote {
    diagnostics.push(
      diagnostic("MGA001", Error, "unclosed quoted token", source, line),
    )
  }
  if tokenized.trailing_escape {
    diagnostics.push(
      diagnostic(
        "MGA002",
        Warning,
        "trailing backslash is literal",
        source,
        line,
      ),
    )
  }
  guard tokenized.tokens is [pattern, .. rest] else { return }
  let escaped_leading_bang = trimmed.has_prefix("\\!")
  if pattern.has_prefix("!") && !escaped_leading_bang {
    diagnostics.push(
      diagnostic(
        "MGA005",
        Error,
        "negative patterns are not allowed in .gitattributes",
        source,
        line,
      ),
    )
    return
  }
  let assignments : Array[Assignment] = []
  for token in rest {
    if parse_assignment_for_line(token, source, line, diagnostics)
      is Some(value) {
      assignments.push(value)
    }
  }
  if assignments.length() == 0 {
    diagnostics.push(
      diagnostic(
        "MGA006",
        Warning,
        "rule has no valid attribute assignments",
        source,
        line,
      ),
    )
  }
  if pattern.has_prefix("[attr]") {
    let name = pattern.unsafe_substring(start=6, end=pattern.length())
    if base_dir.length() > 0 {
      diagnostics.push(
        diagnostic(
          "MGA007",
          Error,
          "attribute macros may only be declared at repository root",
          source,
          line,
        ),
      )
    } else if is_valid_attribute_name(name) {
      macros.push({ name, assignments, source, line, })
    } else {
      diagnostics.push(
        diagnostic("MGA003", Error, "invalid macro name: \{name}", source, line),
      )
    }
  } else {
    if pattern.has_suffix("/") {
      diagnostics.push(
        diagnostic(
          "MGA008",
          Warning,
          "a trailing slash does not recursively match directory contents; use /**",
          source,
          line,
        ),
      )
    }
    rules.push({ pattern, assignments, source, line, base_dir, })
  }
}

///|
/// Parses one `.gitattributes` document without accessing the file system.
pub fn parse(
  content : String,
  source? : String = ".gitattributes",
  base_dir? : String = "",
) -> RuleSet {
  let rules : Array[Rule] = []
  let macros : Array[MacroDefinition] = []
  let diagnostics : Array[Diagnostic] = []
  for index, line in content.split("\n") {
    parse_line(
      normalized_line(line),
      source,
      base_dir,
      index + 1,
      rules,
      macros,
      diagnostics,
    )
  }
  { rules, macros, diagnostics, }
}
