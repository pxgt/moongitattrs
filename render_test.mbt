///|
test "text evaluation is stable and source-aware" {
  let evaluation = parse("*.txt text eol=lf\n").evaluate("notes.txt")
  inspect(
    evaluation.to_text(),
    content=(
      #|path: notes.txt
      #|attributes:
      #|  eol: lf (.gitattributes:1, *.txt)
      #|  text: set (.gitattributes:1, *.txt)
      #|
    ),
  )
}

///|
test "empty evaluation is explicit" {
  inspect(
    parse("*.md text\n").evaluate("main.mbt").to_text(),
    content=(
      #|path: main.mbt
      #|attributes: (none)
      #|
    ),
  )
}

///|
test "evaluation JSON is valid and deterministic" {
  let output = parse("* zeta alpha\n").evaluate("README.md").to_json_string()
  inspect(output.contains("\"name\": \"alpha\""), content="true")
  let ordered = match (output.find("alpha"), output.find("zeta")) {
    (Some(alpha), Some(zeta)) => alpha < zeta
    _ => false
  }
  inspect(ordered, content="true")
}

///|
test "clean audit renders a short Markdown result" {
  inspect(
    parse("*.mbt text eol=lf\n").audit().to_markdown(),
    content=(
      #|# MoonGitAttrs audit
      #|
      #|No diagnostics or policy findings.
      #|
    ),
  )
}

///|
test "audit Markdown includes parser and policy problems" {
  let output = parse("!bad text\n*.txt eol=unix\n").audit().to_markdown()
  inspect(output.contains("MGA005"), content="true")
  inspect(output.contains("MGA103"), content="true")
  inspect(output.contains("| error |"), content="true")
}

///|
test "audit JSON contains stable codes" {
  let output = parse("*.txt text -text\n").audit().to_json_string()
  inspect(output.contains("MGA101"), content="true")
}
