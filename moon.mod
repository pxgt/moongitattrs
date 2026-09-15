// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "Xpeng/moongitattrs"

version = "0.1.0"

readme = "README.md"

repository = "https://github.com/pxgt/moongitattrs"

license = "Apache-2.0"

keywords = [ "git", "gitattributes", "path-matching", "repository-tooling" ]

preferred_target = "wasm-gc"

description = "Parse, evaluate, explain, and audit .gitattributes rules in MoonBit"
