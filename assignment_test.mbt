///|
test "parse all four attribute states" {
  inspect(@moongitattrs.parse_assignment("text").to_token(), content="text")
  inspect(@moongitattrs.parse_assignment("-diff").to_token(), content="-diff")
  inspect(@moongitattrs.parse_assignment("eol=lf").to_token(), content="eol=lf")
  inspect(@moongitattrs.parse_assignment("!merge").to_token(), content="!merge")
}

///|
test "attribute values may be empty or contain equals signs" {
  debug_inspect(
    @moongitattrs.parse_assignment("filter=a=b"),
    content=(
      #|{ name: "filter", state: Value("a=b") }
    ),
  )
  debug_inspect(
    @moongitattrs.parse_assignment("custom="),
    content=(
      #|{ name: "custom", state: Value("") }
    ),
  )
}

///|
test "reject invalid attribute names" {
  try @moongitattrs.parse_assignment("bad/name") catch {
    err => debug_inspect(err, content="InvalidAttributeName(\"bad/name\")")
  } noraise {
    _ => fail("expected invalid name")
  }
  try @moongitattrs.parse_assignment("-") catch {
    err => debug_inspect(err, content="InvalidAttributeName(\"\")")
  } noraise {
    _ => fail("expected missing name")
  }
}

///|
test "validate attribute names" {
  assert_true(@moongitattrs.is_valid_attribute_name("linguist-generated"))
  assert_true(@moongitattrs.is_valid_attribute_name("filter.lfs"))
  assert_false(@moongitattrs.is_valid_attribute_name("-private"))
  assert_false(@moongitattrs.is_valid_attribute_name("with space"))
}
