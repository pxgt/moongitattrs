///|
test "nested files and info attributes follow Git precedence" {
  let rules = @moongitattrs.parse_sources([
    @moongitattrs.AttributeSource::new(".gitattributes", "abc foo bar baz\n"),
    @moongitattrs.AttributeSource::new(
      "t/.gitattributes",
      "ab* merge=filfre\nabc -foo -bar\n*.c frotz\n",
      base_dir="t",
    ),
    @moongitattrs.AttributeSource::new(
      ".git/info/attributes", "a* foo !bar -baz\n",
    ),
  ])
  let result = rules.evaluate("t/abc")
  debug_inspect(result.attribute("foo"), content="Set")
  debug_inspect(result.attribute("bar"), content="Unspecified")
  debug_inspect(result.attribute("baz"), content="Unset")
  debug_inspect(result.attribute("merge"), content="Value(\"filfre\")")
  debug_inspect(result.attribute("frotz"), content="Unspecified")
}

///|
test "deeper source only applies below its directory" {
  let rules = @moongitattrs.parse_sources([
    @moongitattrs.AttributeSource::new(".gitattributes", "*.md text\n"),
    @moongitattrs.AttributeSource::new(
      "docs/.gitattributes",
      "*.md eol=lf\n",
      base_dir="docs",
    ),
  ])
  debug_inspect(
    rules.evaluate("README.md").attribute("eol"),
    content="Unspecified",
  )
  debug_inspect(
    rules.evaluate("docs/guide.md").attribute("eol"),
    content="Value(\"lf\")",
  )
}

///|
test "matching rules expose source order" {
  let rules = @moongitattrs.parse_sources([
    @moongitattrs.AttributeSource::new("root", "* text=auto\n"),
    @moongitattrs.AttributeSource::new(
      "assets",
      "*.png binary\n",
      base_dir="assets",
    ),
  ])
  inspect(
    rules.matching_rules("assets/logo.png").map(rule => rule.source).join(","),
    content="root,assets",
  )
}
