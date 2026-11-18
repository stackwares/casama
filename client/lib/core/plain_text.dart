final _fences = RegExp(r'```[\s\S]*?```');
final _links = RegExp(r'!?\[([^\]]*)\]\([^)]*\)');
final _marks = RegExp(
  r'(^|\s)(#{1,6}|>|[-*+]|\d+\.)\s+|[*_`~]+',
  multiLine: true,
);
final _fenceMarks = RegExp(r'```\w*');
final _space = RegExp(r'\s+');

/// A message as plain words for a preview line: links become their text, Markdown marks and
/// code blocks go, and every run of whitespace (blank lines included) becomes one space. A
/// message that is nothing but code shows the code, so the preview is never blank.
String plainPreview(String markdown) {
  final plain = markdown
      .replaceAll(_fences, ' ')
      .replaceAllMapped(_links, (m) => m[1] ?? '')
      .replaceAllMapped(_marks, (m) => m[1] ?? '')
      .replaceAll(_space, ' ')
      .trim();
  return plain.isNotEmpty
      ? plain
      : markdown.replaceAll(_fenceMarks, ' ').replaceAll(_space, ' ').trim();
}
