///|
test "later matching rules override per attribute" {
  let rules = @moongitattrs.parse(
    (
      #|* text=auto diff
      #|*.png -text -diff
      #|logo.png diff=png
    ),
  )
  let result = rules.evaluate("assets/logo.png")
  debug_inspect(result.attribute("text"), content="Unset")
  debug_inspect(result.attribute("diff"), content="Value(\"png\")")
  debug_inspect(result.attribute("merge"), content="Unspecified")
  debug_inspect(result.matched_rules, content="[0, 1, 2]")
}

///|
test "built-in binary macro expands to Git states" {
  let result = @moongitattrs.parse("*.jpg binary\n").evaluate("photo.jpg")
  debug_inspect(result.attribute("binary"), content="Set")
  debug_inspect(result.attribute("text"), content="Unset")
  debug_inspect(result.attribute("diff"), content="Unset")
  debug_inspect(result.attribute("merge"), content="Unset")
}

///|
test "custom macros expand and direct rules may override them" {
  let rules = @moongitattrs.parse(
    (
      #|[attr]generated linguist-generated -diff
      #|generated/** generated
      #|generated/keep.txt !linguist-generated diff
    ),
  )
  let generated = rules.evaluate("generated/api.json")
  debug_inspect(generated.attribute("linguist-generated"), content="Set")
  debug_inspect(generated.attribute("diff"), content="Unset")
  let kept = rules.evaluate("generated/keep.txt")
  debug_inspect(kept.attribute("linguist-generated"), content="Unspecified")
  debug_inspect(kept.attribute("diff"), content="Set")
}

///|
test "evaluate many preserves requested path order" {
  let results = @moongitattrs.parse("*.md text\n*.png binary\n").evaluate_many([
    "README.md", "logo.png",
  ])
  inspect(
    results.map(result => result.path).join(","),
    content="README.md,logo.png",
  )
  debug_inspect(results[0].attribute("text"), content="Set")
  debug_inspect(results[1].attribute("binary"), content="Set")
}
