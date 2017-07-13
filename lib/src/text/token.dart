import 'package:source_span/source_span.dart';

class Token {
  final TokenType type;
  final FileSpan span;

  Token(this.type, this.span);

  @override
  String toString() => '"${span.text}" => $type';
}

enum TokenType {
  // Plaintext
  PLAINTEXT,

  // Braces
  DOUBLE_CURLY_L,
  DOUBLE_CURLY_R,
  CURLY_PERCENT_L,
  CURLY_PERCENT_R,
  LBRACKET,
  RBRACKET,
  LPAREN,
  RPAREN,

  // Keywords
  ASSIGN,
  BREAK,
  CAPTURE,
  END_CAPTURE,
  CASE,
  END_CASE,
  COMMENT,
  END_COMMENT,
  COLS,
  CONTINUE,
  CYCLE,
  FOR,
  END_FOR,
  IN,
  INCREMENT,
  DECREMENT,
  IF,
  END_IF,
  ELSIF,
  ELSE,
  LIMIT,
  OFFSET,
  RAW,
  END_RAW,
  TABLE_ROW,
  END_TABLE_ROW,
  UNLESS,
  END_UNLESS,
  WHEN,

  // Operators
  EQU,
  NEQU,
  LT,
  LTE,
  GT,
  GTE,
  AND,
  OR,
  CONTAINS,
  REVERSED,

  // Symbols
  COLON,
  DOT,
  ELLIPSIS,
  EQUALS,
  PIPE,

  // Expressions
  ID,
  NUMBER,
  STRING,
  BOOLEAN
}
