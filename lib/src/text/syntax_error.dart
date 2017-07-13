import 'package:source_span/source_span.dart';

class SyntaxError implements Exception {
  final String message;
  final FileSpan span;

  SyntaxError(this.message, this.span);

  @override
  String toString() => 'Syntax error: $message\n' + span.highlight(color: true);
}