///|
test "audit catches repeated assignments" {
  let report = parse("*.txt text -text\n").audit()
  inspect(report.findings.length(), content="1")
  inspect(report.findings[0].code, content="MGA101")
}

///|
test "audit rejects reserved names" {
  let report = parse("* builtin_objectformat=sha1\n").audit()
  inspect(report.has_errors(), content="true")
  inspect(report.findings[0].code, content="MGA102")
}

///|
test "audit validates eol values" {
  let invalid = parse("*.sh text eol=unix\n").audit()
  inspect(invalid.findings[0].code, content="MGA103")
  let valid = parse("*.sh text eol=lf\n*.bat text eol=crlf\n").audit()
  inspect(valid.findings.length(), content="0")
}

///|
test "audit explains non-set macro usage" {
  let report = parse("[attr]media binary\n*.png -media\n").audit()
  inspect(report.findings.length(), content="1")
  inspect(report.findings[0].code, content="MGA105")
}

///|
test "audit catches binary and text conflict" {
  let report = parse("*.dat binary text\n").audit()
  inspect(report.findings.length(), content="1")
  inspect(report.findings[0].code, content="MGA106")
}

///|
test "audit preserves parser diagnostics" {
  let report = parse("!*.txt text\n").audit()
  inspect(report.diagnostics.length(), content="1")
  inspect(report.has_errors(), content="true")
}
