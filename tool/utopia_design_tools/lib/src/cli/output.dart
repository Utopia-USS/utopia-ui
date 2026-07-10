import 'dart:convert';

/// Severity of a single [Finding] reported by a tool.
enum FindingSeverity {
  /// A gate violation; makes the overall run fail (exit code 1).
  error,

  /// A non-fatal observation; does not affect the exit code.
  warning,
}

/// A single actionable finding produced by a validation or generation gate.
///
/// [path] is a dotted, jsonPath-ish reference into the token document (e.g.
/// `spacing.md` or `shadow.sm[0].color`) identifying where the problem lives.
/// [message] is a complete, one-line, human-actionable description.
class Finding {
  /// Creates a finding with the given [severity], [path] and [message].
  const Finding({required this.severity, required this.path, required this.message});

  /// Convenience constructor for an error-level finding.
  const Finding.error(String path, String message) : this(severity: FindingSeverity.error, path: path, message: message);

  /// Convenience constructor for a warning-level finding.
  const Finding.warning(String path, String message)
    : this(severity: FindingSeverity.warning, path: path, message: message);

  /// Severity of this finding.
  final FindingSeverity severity;

  /// Dotted path into the token document this finding refers to.
  final String path;

  /// One-line, human-actionable description of the problem.
  final String message;

  /// Text-mode rendering: `ERROR <path>: <message>` or `WARN <path>: <message>`.
  String toLine() {
    final label = severity == FindingSeverity.error ? 'ERROR' : 'WARN';
    return '$label $path: $message';
  }

  /// JSON-mode rendering: `{"path": ..., "message": ...}` (severity is implied
  /// by which array the finding is placed in; see [FindingReport.toJson]).
  Map<String, dynamic> toJsonEntry() => {'path': path, 'message': message};
}

/// A collection of [Finding]s from a single tool run, with rendering for both
/// the text and `--json` output modes described in protocol SPEC section 5.
class FindingReport {
  /// Creates a report from a flat list of findings (any order; both
  /// severities may be interleaved).
  FindingReport(List<Finding> findings) : findings = List.unmodifiable(findings);

  /// All findings collected during the run.
  final List<Finding> findings;

  /// Errors only, in original order.
  List<Finding> get errors => findings.where((f) => f.severity == FindingSeverity.error).toList();

  /// Warnings only, in original order.
  List<Finding> get warnings => findings.where((f) => f.severity == FindingSeverity.warning).toList();

  /// Whether this report contains at least one error.
  bool get hasErrors => errors.isNotEmpty;

  /// The process exit code this report implies: 1 if there is at least one
  /// error, 0 otherwise. Callers with their own usage/I-O errors (exit 2)
  /// short-circuit before constructing a report.
  int get exitCode => hasErrors ? 1 : 0;

  /// Renders the human-readable text form: one `ERROR`/`WARN` line per
  /// finding (errors first, then warnings), followed by a summary line.
  String toText() {
    final buffer = StringBuffer();
    for (final finding in errors) {
      buffer.writeln(finding.toLine());
    }
    for (final finding in warnings) {
      buffer.writeln(finding.toLine());
    }
    buffer.write('${errors.length} error(s), ${warnings.length} warning(s)');
    return buffer.toString();
  }

  /// Renders the `--json` form: `{"status": "ok"|"fail", "errors": [...],
  /// "warnings": [...]}`.
  String toJson() {
    final map = {
      'status': hasErrors ? 'fail' : 'ok',
      'errors': errors.map((f) => f.toJsonEntry()).toList(),
      'warnings': warnings.map((f) => f.toJsonEntry()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }
}
