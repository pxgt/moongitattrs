///|
fn normalize_repository_path(path : String) -> String {
  let out = StringBuilder(size_hint=path.length())
  for char in path {
    out.write_char(if char == '\\' { '/' } else { char })
  }
  let normalized = out.to_string()
  let without_dot = match normalized.strip_prefix("./") {
    Some(rest) => rest.to_owned()
    None => normalized
  }
  match without_dot.strip_prefix("/") {
    Some(rest) => rest.to_owned()
    None => without_dot
  }
}

///|
fn relative_to_base(path : String, base_dir : String) -> String? {
  let path = normalize_repository_path(path)
  let base = normalize_repository_path(base_dir).trim_end(chars="/").to_owned()
  if base.length() == 0 {
    return Some(path)
  }
  if path == base {
    return Some("")
  }
  let prefix = "\{base}/"
  match path.strip_prefix(prefix) {
    Some(rest) => Some(rest.to_owned())
    None => None
  }
}

///|
fn class_match(
  pattern : Array[Char],
  start : Int,
  value : Char,
) -> (Bool, Int)? {
  let mut index = start + 1
  guard index < pattern.length() else { return None }
  let mut negated = false
  if pattern[index] == '!' || pattern[index] == '^' {
    negated = true
    index += 1
  }
  let mut matched = false
  let mut has_item = false
  while index < pattern.length() && pattern[index] != ']' {
    has_item = true
    let lower = pattern[index]
    if index + 2 < pattern.length() &&
      pattern[index + 1] == '-' &&
      pattern[index + 2] != ']' {
      let upper = pattern[index + 2]
      if value >= lower && value <= upper {
        matched = true
      }
      index += 3
    } else {
      if value == lower {
        matched = true
      }
      index += 1
    }
  }
  guard index < pattern.length() && has_item else { None }
  Some((if negated { !matched } else { matched }, index + 1))
}

///|
fn wildmatch_from(
  pattern : Array[Char],
  text : Array[Char],
  pattern_index : Int,
  text_index : Int,
  memo : Map[String, Bool],
) -> Bool {
  let key = "\{pattern_index}:\{text_index}"
  if memo.get(key) is Some(result) {
    return result
  }
  let result = if pattern_index == pattern.length() {
    text_index == text.length()
  } else {
    match pattern[pattern_index] {
      '*' => {
        let mut next = pattern_index + 1
        while next < pattern.length() && pattern[next] == '*' {
          next += 1
        }
        let crosses_directories = next - pattern_index >= 2
        let zero_width_next = if crosses_directories &&
          next < pattern.length() &&
          pattern[next] == '/' {
          next + 1
        } else {
          next
        }
        if wildmatch_from(pattern, text, zero_width_next, text_index, memo) {
          true
        } else if text_index < text.length() &&
          (crosses_directories || text[text_index] != '/') {
          wildmatch_from(pattern, text, pattern_index, text_index + 1, memo)
        } else {
          false
        }
      }
      '?' =>
        text_index < text.length() &&
        text[text_index] != '/' &&
        wildmatch_from(pattern, text, pattern_index + 1, text_index + 1, memo)
      '[' =>
        if text_index < text.length() && text[text_index] != '/' {
          match class_match(pattern, pattern_index, text[text_index]) {
            Some((accepted, next)) =>
              accepted &&
              wildmatch_from(pattern, text, next, text_index + 1, memo)
            None =>
              text[text_index] == '[' &&
              wildmatch_from(
                pattern,
                text,
                pattern_index + 1,
                text_index + 1,
                memo,
              )
          }
        } else {
          false
        }
      '\\' => {
        let literal_index = if pattern_index + 1 < pattern.length() {
          pattern_index + 1
        } else {
          pattern_index
        }
        text_index < text.length() &&
        text[text_index] == pattern[literal_index] &&
        wildmatch_from(pattern, text, literal_index + 1, text_index + 1, memo)
      }
      literal =>
        text_index < text.length() &&
        text[text_index] == literal &&
        wildmatch_from(pattern, text, pattern_index + 1, text_index + 1, memo)
    }
  }
  memo[key] = result
  result
}

///|
fn wildmatch(pattern : String, text : String) -> Bool {
  wildmatch_from(pattern.to_array(), text.to_array(), 0, 0, {})
}

///|
/// Matches one Git attribute pattern against a repository-relative path.
///
/// A pattern without a slash is matched against every path component. A
/// single `*` never crosses `/`, while `**` may cross directory boundaries.
pub fn match_pattern(
  pattern : String,
  path : String,
  base_dir? : String = "",
) -> Bool {
  guard relative_to_base(path, base_dir) is Some(relative) else { return false }
  let without_dot = match pattern.strip_prefix("./") {
    Some(rest) => rest.to_owned()
    None => pattern
  }
  let normalized_pattern = without_dot.trim_start(chars="/").to_owned()
  guard normalized_pattern.length() > 0 else { return false }
  if normalized_pattern.find("/") is Some(_) {
    wildmatch(normalized_pattern, relative)
  } else {
    relative
    .split("/")
    .any(component => wildmatch(normalized_pattern, component.to_owned()))
  }
}
