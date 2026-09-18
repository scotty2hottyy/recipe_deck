import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// Cleans website text without changing recipe quantities or preparation notes.
String cleanRecipeText(String value) {
  final fragment = html_parser.parseFragment(value);
  for (final element in fragment.querySelectorAll('script, style')) {
    element.remove();
  }
  // Keep words separated where the source uses layout instead of spaces.
  for (final element in fragment.querySelectorAll('br, p, div, li')) {
    element.nodes.insert(0, Text(' '));
    element.nodes.add(Text(' '));
  }
  return (fragment.text ?? '').replaceAll(RegExp(r'[\s\u00a0]+'), ' ').trim();
}
