import 'package:liquid/src/text/scanner.dart';
import 'package:liquid/src/text/syntax_error.dart';
import 'package:liquid/src/text/token.dart';
import 'package:test/test.dart';

final Matcher throwsSyntaxError = throwsA(const isInstanceOf<SyntaxError>());

List<Token> scan(String text) => (new Scanner(text)..scan()).tokens;