///|
test "literal wildcard and question mark matching" {
  assert_true(@moongitattrs.match_pattern("README.md", "README.md"))
  assert_true(@moongitattrs.match_pattern("*.md", "docs/guide.md"))
  assert_false(@moongitattrs.match_pattern("*.md", "docs/guide.txt"))
  assert_true(@moongitattrs.match_pattern("file?.txt", "a/file1.txt"))
  assert_false(@moongitattrs.match_pattern("file?.txt", "file10.txt"))
}

///|
test "single star does not cross directories" {
  assert_true(@moongitattrs.match_pattern("docs/*.md", "docs/readme.md"))
  assert_false(@moongitattrs.match_pattern("docs/*.md", "docs/guides/start.md"))
}

///|
test "double star crosses directory boundaries" {
  assert_true(@moongitattrs.match_pattern("docs/**/index.md", "docs/index.md"))
  assert_true(
    @moongitattrs.match_pattern(
      "docs/**/index.md", "docs/guides/setup/index.md",
    ),
  )
  assert_true(@moongitattrs.match_pattern("assets/**", "assets/icons/a.svg"))
}

///|
test "character classes and negated classes" {
  assert_true(@moongitattrs.match_pattern("file[0-9].txt", "file7.txt"))
  assert_false(@moongitattrs.match_pattern("file[0-9].txt", "filex.txt"))
  assert_true(@moongitattrs.match_pattern("file[!0-9].txt", "filex.txt"))
  assert_false(@moongitattrs.match_pattern("file[!0-9].txt", "file7.txt"))
}

///|
test "base directory scopes patterns" {
  assert_true(
    @moongitattrs.match_pattern("*.md", "docs/guide.md", base_dir="docs"),
  )
  assert_true(
    @moongitattrs.match_pattern(
      "generated/**",
      "docs/generated/api.json",
      base_dir="docs",
    ),
  )
  assert_false(
    @moongitattrs.match_pattern("*.md", "README.md", base_dir="docs"),
  )
}

///|
test "normalize slash prefixes and Windows separators" {
  assert_true(@moongitattrs.match_pattern("/src/**", ".\\src\\lib\\a.mbt"))
}

///|
test "escaped metacharacters are literal" {
  assert_true(@moongitattrs.match_pattern("file\\*.txt", "file*.txt"))
  assert_false(@moongitattrs.match_pattern("file\\*.txt", "file1.txt"))
}
