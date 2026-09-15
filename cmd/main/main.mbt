///|
fn usage() -> String {
  (
    #|moongitattrs - inspect and audit .gitattributes rules
    #|
    #|Usage:
    #|  moon run cmd/main
    #|  moon run cmd/main -- explain <attributes-file> <repository-path>
    #|  moon run cmd/main -- explain-json <attributes-file> <repository-path>
    #|  moon run cmd/main -- audit <attributes-file>
    #|  moon run cmd/main -- match <pattern> <repository-path>
    #|
    #|With no arguments, the command runs a built-in reproducible example.
    #|
  )
}

///|
fn read_rules(path : String) -> @lib.RuleSet raise {
  @lib.parse(@fs.read_file_to_string(path), source=path)
}

///|
fn run_demo() -> Unit {
  let rules = @lib.parse(
    (
      #|[attr]docs text diff
      #|*.md docs eol=lf
      #|assets/** binary
      #|README.md export-subst
      #|
    ),
  )
  println(rules.evaluate("README.md").to_text())
  println(rules.audit().to_markdown())
}

///|
fn run(args : Array[String]) -> Unit raise {
  if args.length() <= 1 {
    run_demo()
    return
  }
  match args[1] {
    "help" | "--help" | "-h" => println(usage())
    "explain" =>
      if args.length() != 4 {
        raise Failure("explain expects an attributes file and repository path")
      } else {
        println(read_rules(args[2]).evaluate(args[3]).to_text())
      }
    "explain-json" =>
      if args.length() != 4 {
        raise Failure(
          "explain-json expects an attributes file and repository path",
        )
      } else {
        println(read_rules(args[2]).evaluate(args[3]).to_json_string())
      }
    "audit" =>
      if args.length() != 3 {
        raise Failure("audit expects an attributes file")
      } else {
        let report = read_rules(args[2]).audit()
        println(report.to_markdown())
        if report.has_errors() {
          @sys.exit(2)
        }
      }
    "match" =>
      if args.length() != 4 {
        raise Failure("match expects a pattern and repository path")
      } else {
        println(@lib.match_pattern(args[2], args[3]))
      }
    command => raise Failure("unknown command '\{command}'; run with --help")
  }
}

///|
fn main {
  try run(@env.args()) catch {
    error => {
      println("moongitattrs: \{error}")
      @sys.exit(1)
    }
  } noraise {
    _ => ()
  }
}
