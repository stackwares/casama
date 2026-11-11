/// Shown in place of a value that's missing (D-190): an em dash, the mark for "no value" in
/// every language, so it needs no translation.
const String kMissingValue = '—';

/// Text from the server that may be missing: null, empty, blank, or the word "null" that a
/// serializer wrote. Never put such a value on screen as it is.
extension UsableText on String? {
  /// True when there is real text to show.
  bool get isUsable {
    final String? value = this;

    return value != null && value.trim().isNotEmpty && value != 'null';
  }

  /// The text, or [placeholder] (an em dash unless given) when it isn't usable.
  String orPlaceholder([String placeholder = kMissingValue]) {
    if (!isUsable) return placeholder;

    return this!;
  }
}
