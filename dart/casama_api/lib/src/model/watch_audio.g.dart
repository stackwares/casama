// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_audio.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchAudioCWProxy {
  WatchAudio data(String data);

  WatchAudio mime(WatchAudioMimeEnum mime);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchAudio(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchAudio(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchAudio call({String data, WatchAudioMimeEnum mime});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchAudio.copyWith(...)` or call `instanceOfWatchAudio.copyWith.fieldName(value)` for a single field.
class _$WatchAudioCWProxyImpl implements _$WatchAudioCWProxy {
  const _$WatchAudioCWProxyImpl(this._value);

  final WatchAudio _value;

  @override
  WatchAudio data(String data) => call(data: data);

  @override
  WatchAudio mime(WatchAudioMimeEnum mime) => call(mime: mime);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchAudio(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchAudio(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchAudio call({
    Object? data = const $CopyWithPlaceholder(),
    Object? mime = const $CopyWithPlaceholder(),
  }) {
    return WatchAudio(
      data: data == const $CopyWithPlaceholder() || data == null
          ? _value.data
          // ignore: cast_nullable_to_non_nullable
          : data as String,
      mime: mime == const $CopyWithPlaceholder() || mime == null
          ? _value.mime
          // ignore: cast_nullable_to_non_nullable
          : mime as WatchAudioMimeEnum,
    );
  }
}

extension $WatchAudioCopyWith on WatchAudio {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchAudio.copyWith(...)` or `instanceOfWatchAudio.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchAudioCWProxy get copyWith => _$WatchAudioCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchAudio _$WatchAudioFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WatchAudio', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['data', 'mime']);
      final val = WatchAudio(
        data: $checkedConvert('data', (v) => v as String),
        mime: $checkedConvert(
          'mime',
          (v) => $enumDecode(_$WatchAudioMimeEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$WatchAudioToJson(WatchAudio instance) =>
    <String, dynamic>{
      'data': instance.data,
      'mime': _$WatchAudioMimeEnumEnumMap[instance.mime]!,
    };

const _$WatchAudioMimeEnumEnumMap = {
  WatchAudioMimeEnum.audioSlashAac: 'audio/aac',
  WatchAudioMimeEnum.audioSlashMp4: 'audio/mp4',
  WatchAudioMimeEnum.audioSlashM4a: 'audio/m4a',
  WatchAudioMimeEnum.audioSlashXM4a: 'audio/x-m4a',
  WatchAudioMimeEnum.audioSlashOgg: 'audio/ogg',
  WatchAudioMimeEnum.audioSlashWebm: 'audio/webm',
  WatchAudioMimeEnum.audioSlash3gpp: 'audio/3gpp',
  WatchAudioMimeEnum.audioSlashWav: 'audio/wav',
};
