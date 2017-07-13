import 'dart:collection';
import 'package:string_scanner/string_scanner.dart';
import 'syntax_error.dart';
import 'token.dart';

// Whitespace
final RegExp _whitespace = new RegExp(r'[ \n\r\t]+');

// Braces
final RegExp _doubleCurlyL = new RegExp(r'{{-?');
final RegExp _curlyPercentL = new RegExp(r'{%-?');

// Expressions
final RegExp _id = new RegExp(r'[A-Za-z_][A-Za-z0-9_]*');
final RegExp _number = new RegExp(r'-?[0-9]+(\.[0-9]+)?(E|e(\+|-)?[0-9]+)?');
final RegExp _string1 = new RegExp(
    r"'((\\(['\\/bfnrt]|(u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])))|([^'\\]))*'");
final RegExp _string2 = new RegExp(
    r'"((\\(["\\/bfnrt]|(u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])))|([^"\\]))*"');
final RegExp _boolean = new RegExp(r'true|false');

class Scanner {
  LineScannerState _plainTextStart;
  SpanScanner _scanner;
  final List<Token> _tokens = [];
  final String text;
  final sourceUrl;

  Scanner(this.text, {this.sourceUrl}) {
    _scanner = new SpanScanner(text, sourceUrl: sourceUrl);
  }

  List<Token> get tokens => new List<Token>.unmodifiable(_tokens);

  void scan() {
    while (!_scanner.isDone) {
      if (_scanner.matches(_doubleCurlyL) || _scanner.matches(_curlyPercentL)) {
        _flush();
        _scanTemplate();
      } else {
        _plainTextStart ??= _scanner.state;
        _scanner.readChar();
      }
    }

    _flush();
  }

  void _flush() {
    if (_plainTextStart != null) {
      _tokens.add(
          new Token(TokenType.PLAINTEXT, _scanner.spanFrom(_plainTextStart)));
      _plainTextStart = null;
    }
  }

  void _scanTemplate() {
    var output = <Token>[];
    var braceStack = new Queue<Token>();
    Token lastScanned;
    _scanner.scan(_whitespace);

    while (!_scanner.isDone) {
      var tokens = <Token>[];
      _patterns.forEach((pattern, type) {
        if (_scanner.matches(pattern))
          tokens.add(new Token(type, _scanner.lastSpan));
      });

      if (tokens.isEmpty) {
        var state = _scanner.state;
        var ch = new String.fromCharCode(_scanner.readChar());
        throw new SyntaxError(
            'Unexpected character "$ch".', _scanner.spanFrom(state));
      }

      // Choose longest
      tokens.sort((a, b) => b.span.text.length.compareTo(a.span.text.length));
      var token = lastScanned = tokens.first;

      // If this is a LEFT brace, keep track of it.
      if (token.type == TokenType.CURLY_PERCENT_L ||
          token.type == TokenType.DOUBLE_CURLY_L)
        braceStack.addLast(token);

      // If this is a RIGHT brace, ensure it is closing the correct LEFT brace.
      else if (token.type == TokenType.CURLY_PERCENT_R ||
          token.type == TokenType.DOUBLE_CURLY_R) {
        if (braceStack.isEmpty) {
          throw new SyntaxError(
              'Unmatched "${token.span.text}".', lastScanned.span);
        }

        var left = braceStack.removeLast();
        bool mismatch = (left.type == TokenType.CURLY_PERCENT_L &&
                token.type == TokenType.DOUBLE_CURLY_R) ||
            (left.type == TokenType.DOUBLE_CURLY_L &&
                token.type == TokenType.CURLY_PERCENT_R);

        if (mismatch) {
          var fix = left.type == TokenType.CURLY_PERCENT_L ? '%}' : '}}';
          throw new SyntaxError(
              'Cannot close "${left.span.text}" with "${token.span.text}"; use "$fix" instead.',
              token.span);
        }
      }

      // Add the token and consume it
      output.add(token);
      _scanner.scan(token.span.text);

      // If we've closed all braces, exit loop
      if (braceStack.isEmpty) break;

      // Consume extraneous whitespace
      _scanner.scan(_whitespace);
    }

    // If the brace stack is not empty, throw an error about an unclosed brace.
    if (braceStack.isNotEmpty) {
      var left = braceStack.removeLast();
      var fix = left.type == TokenType.CURLY_PERCENT_L ? '%}' : '}}';
      throw new SyntaxError(
          'Unclosed "${left.span.text}"; expected "$fix".', lastScanned.span);
    }

    // Add all tokens we just scanned
    _tokens.addAll(output);
  }
}

final Map<Pattern, TokenType> _patterns = {
  // Braces
  _doubleCurlyL: TokenType.DOUBLE_CURLY_L,
  '}}': TokenType.DOUBLE_CURLY_R,
  _curlyPercentL: TokenType.CURLY_PERCENT_L,
  '%}': TokenType.CURLY_PERCENT_R,
  '[': TokenType.LBRACKET,
  ']': TokenType.RBRACKET,
  '(': TokenType.LPAREN,
  ')': TokenType.RPAREN,

  // Keywords
  'assign': TokenType.ASSIGN,
  'break': TokenType.BREAK,
  'capture': TokenType.CAPTURE,
  'endcapture': TokenType.END_CAPTURE,
  'case': TokenType.CASE,
  'endcase': TokenType.END_CASE,
  'comment': TokenType.COMMENT,
  'endcomment': TokenType.END_COMMENT,
  'cols': TokenType.COLS,
  'continue': TokenType.CONTINUE,
  'cycle': TokenType.CYCLE,
  'for': TokenType.FOR,
  'endfor': TokenType.END_FOR,
  'in': TokenType.IN,
  'increment': TokenType.INCREMENT,
  'decrement': TokenType.DECREMENT,
  'if': TokenType.IF,
  'endif': TokenType.END_IF,
  'elsif': TokenType.ELSIF,
  'else': TokenType.ELSE,
  'limit': TokenType.LIMIT,
  'offset': TokenType.OFFSET,
  'raw': TokenType.RAW,
  'endraw': TokenType.END_RAW,
  'tablerow': TokenType.TABLE_ROW,
  'endtablerow': TokenType.END_TABLE_ROW,
  'unless': TokenType.UNLESS,
  'endunless': TokenType.END_UNLESS,
  'when': TokenType.WHEN,

  // Operators
  '==': TokenType.EQU,
  '!=': TokenType.NEQU,
  '<': TokenType.LT,
  '<=': TokenType.LTE,
  '>': TokenType.GT,
  '>=': TokenType.GTE,
  'and': TokenType.AND,
  'or': TokenType.OR,
  'contains': TokenType.CONTAINS,
  'reversed': TokenType.REVERSED,

  // Symbols
  ':': TokenType.COLON,
  '.': TokenType.DOT,
  '..': TokenType.ELLIPSIS,
  '=': TokenType.EQUALS,
  '|': TokenType.PIPE,

  // Expressions
  _id: TokenType.ID,
  _number: TokenType.NUMBER,
  _string1: TokenType.STRING,
  _string2: TokenType.STRING,
  _boolean: TokenType.BOOLEAN,
};
