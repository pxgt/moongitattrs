///|
/// The four states an attribute may have in Git's attribute model.
pub(all) enum AttributeState {
  Set
  Unset
  Value(String)
  Unspecified
} derive(Debug, Eq, ToJson)

///|
/// One attribute operation attached to a pattern.
pub(all) struct Assignment {
  name : String
  state : AttributeState
} derive(Debug, Eq, ToJson)

///|
/// Severity used by source diagnostics and policy findings.
pub(all) enum Severity {
  Info
  Warning
  Error
} derive(Debug, Eq, ToJson)

///|
/// A stable, source-aware diagnostic.
pub(all) struct Diagnostic {
  code : String
  severity : Severity
  message : String
  source : String
  line : Int
  column : Int
} derive(Debug, Eq, ToJson)

///|
/// A parsed attribute rule.
pub(all) struct Rule {
  pattern : String
  assignments : Array[Assignment]
  source : String
  line : Int
  base_dir : String
} derive(Debug, Eq, ToJson)

///|
/// A named attribute macro declared by `[attr]name`.
pub(all) struct MacroDefinition {
  name : String
  assignments : Array[Assignment]
  source : String
  line : Int
} derive(Debug, Eq, ToJson)

///|
/// Result of parsing one or more attribute sources.
pub(all) struct RuleSet {
  rules : Array[Rule]
  macros : Array[MacroDefinition]
  diagnostics : Array[Diagnostic]
} derive(Debug, Eq, ToJson)

///|
/// The rule responsible for the current value of an attribute.
pub(all) struct ResolvedAttribute {
  name : String
  state : AttributeState
  source : String
  line : Int
  pattern : String
  rule_index : Int
} derive(Debug, Eq, ToJson)

///|
/// Evaluation result for one repository-relative path.
pub(all) struct Evaluation {
  path : String
  attributes : Array[ResolvedAttribute]
  matched_rules : Array[Int]
} derive(Debug, Eq, ToJson)

///|
/// A `.gitattributes` source and the repository directory that contains it.
pub(all) struct AttributeSource {
  source : String
  base_dir : String
  content : String
} derive(Debug, Eq)

///|
pub(all) suberror AttributeError {
  InvalidAssignment(String)
  InvalidAttributeName(String)
} derive(Debug, Eq)
