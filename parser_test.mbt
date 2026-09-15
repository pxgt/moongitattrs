///|
test "parse comments blank lines and rules" {
  let rules = @moongitattrs.parse(
    (
      #|# repository defaults
      #|* text=auto
      #|*.png -text diff=png
      #|
    ),
  )
  assert_eq(rules.rules.length(), 2)
  assert_eq(rules.diagnostics.length(), 0)
  inspect(rules.rules[0].pattern, content="*")
  debug_inspect(
    rules.rules[1].assignments,
    content=(
      #|[
      #|  { name: "text", state: Unset },
      #|  { name: "diff", state: Value("png") },
      #|]
    ),
  )
}

///|
test "parse quoted patterns and escaped spaces" {
  let rules = @moongitattrs.parse(
    (
      #|"docs/user guide.md" linguist-documentation
      #|assets\ with\ spaces/** export-ignore
    ),
  )
  assert_eq(rules.rules.length(), 2)
  inspect(rules.rules[0].pattern, content="docs/user guide.md")
  inspect(rules.rules[1].pattern, content="assets with spaces/**")
}

///|
test "collect recoverable diagnostics" {
  let rules = @moongitattrs.parse(
    (
      #|!secret/** export-ignore
      #|docs/
      #|"unterminated text
    ),
  )
  inspect(
    rules.diagnostics.map(d => d.code).join(","),
    content="MGA005,MGA006,MGA008,MGA001,MGA006",
  )
}

///|
test "parse root macro and reject nested macro" {
  let root = @moongitattrs.parse("[attr]binary -diff -merge -text\n")
  assert_eq(root.macros.length(), 1)
  inspect(root.macros[0].name, content="binary")
  let nested = @moongitattrs.parse(
    "[attr]generated linguist-generated\n",
    source="docs/.gitattributes",
    base_dir="docs",
  )
  inspect(nested.diagnostics[0].code, content="MGA007")
}

///|
test "escaped leading markers remain literal patterns" {
  let rules = @moongitattrs.parse("\\!important text\n\\#manifest text\n")
  inspect(rules.diagnostics.length(), content="0")
  inspect(rules.rules[0].pattern, content="!important")
  inspect(rules.rules[1].pattern, content="#manifest")
}
