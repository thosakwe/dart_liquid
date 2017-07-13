import 'package:test/test.dart';
import 'common.dart';

main() {
  test('curlies with single id between', () {
    var tokens = scan('{{ hello }}');
    print(tokens);
  });

  test('just plaintext', () {
    var tokens = scan('hello\nworld');
    print(tokens);
  });

  test('curly, plaintext, curly, plaintext', () {
    var tokens = scan('{{ hello }}world{% foo %}bar');
    print(tokens);
  });

  test('multiline', () {
    var tokens = scan(
'''
{% if product.tags contains 'Hello' %}
  This product has been tagged with 'Hello'.
{% endif %}
'''.trim()
    );
    print(tokens);
  });

  group('syntax errors', () {
    test('within braces', () {
      expect(() => scan('{{-- hello }}'), throwsSyntaxError);
      expect(() => scan('{{ %}'), throwsSyntaxError);
      expect(() => scan('{% }}'), throwsSyntaxError);
    });
  });
}