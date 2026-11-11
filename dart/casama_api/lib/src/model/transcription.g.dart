// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcription.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TranscriptionCWProxy {
  Transcription text(String text);

  Transcription provider(String provider);

  Transcription seconds(num seconds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Transcription(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Transcription(...).copyWith(id: 12, name: "My name")
  /// ```
  Transcription call({String text, String provider, num seconds});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTranscription.copyWith(...)` or call `instanceOfTranscription.copyWith.fieldName(value)` for a single field.
class _$TranscriptionCWProxyImpl implements _$TranscriptionCWProxy {
  const _$TranscriptionCWProxyImpl(this._value);

  final Transcription _value;

  @override
  Transcription text(String text) => call(text: text);

  @override
  Transcription provider(String provider) => call(provider: provider);

  @override
  Transcription seconds(num seconds) => call(seconds: seconds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Transcription(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Transcription(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Transcription call({
    Object? text = const $CopyWithPlaceholder(),
    Object? provider = const $CopyWithPlaceholder(),
    Object? seconds = const $CopyWithPlaceholder(),
  }) {
    return Transcription(
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
      provider: provider == const $CopyWithPlaceholder() || provider == null
          ? _value.provider
          // ignore: cast_nullable_to_non_nullable
          : provider as String,
      seconds: seconds == const $CopyWithPlaceholder() || seconds == null
          ? _value.seconds
          // ignore: cast_nullable_to_non_nullable
          : seconds as num,
    );
  }
}

extension $TranscriptionCopyWith on Transcription {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTranscription.copyWith(...)` or `instanceOfTranscription.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TranscriptionCWProxy get copyWith => _$TranscriptionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transcription _$TranscriptionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Transcription', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['text', 'provider', 'seconds']);
      final val = Transcription(
        text: $checkedConvert('text', (v) => v as String),
        provider: $checkedConvert('provider', (v) => v as String),
        seconds: $checkedConvert('seconds', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$TranscriptionToJson(Transcription instance) =>
    <String, dynamic>{
      'text': instance.text,
      'provider': instance.provider,
      'seconds': instance.seconds,
    };
