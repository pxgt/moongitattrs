///|
fn valid_attribute_char(char : Char) -> Bool {
  char.is_ascii_alphabetic() ||
  char.is_ascii_digit() ||
  char == '-' ||
  char == '_' ||
  char == '.'
}

///|
/// Returns whether `name` follows Git's attribute-name grammar.
pub fn is_valid_attribute_name(name : String) -> Bool {
  guard name.length() > 0 else { false }
  guard name.get_char(0) is Some(first) else { false }
  if first == '-' || !valid_attribute_char(first) {
    return false
  }
  for char in name {
    if !valid_attribute_char(char) {
      return false
    }
  }
  true
}

///|
/// Parses one attribute token such as `text`, `-diff`, `eol=lf`, or `!merge`.
pub fn parse_assignment(token : String) -> Assignment raise AttributeError {
  let trimmed = token.trim().to_owned()
  guard trimmed.length() > 0 else { raise InvalidAssignment(token) }
  let (name, state) = if trimmed.has_prefix("-") {
    (trimmed.unsafe_substring(start=1, end=trimmed.length()), Unset)
  } else if trimmed.has_prefix("!") {
    (trimmed.unsafe_substring(start=1, end=trimmed.length()), Unspecified)
  } else {
    match trimmed.split_once("=") {
      Some((name, value)) => (name.to_owned(), Value(value.to_owned()))
      None => (trimmed, Set)
    }
  }
  guard is_valid_attribute_name(name) else { raise InvalidAttributeName(name) }
  { name, state, }
}

///|
/// Converts an assignment back to its canonical token form.
pub fn Assignment::to_token(self : Assignment) -> String {
  match self.state {
    Set => self.name
    Unset => "-\{self.name}"
    Unspecified => "!\{self.name}"
    Value(value) => "\{self.name}=\{value}"
  }
}
