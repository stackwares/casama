// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_notice.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateNoticeCWProxy {
  UpdateNotice current(String current);

  UpdateNotice latest(String? latest);

  UpdateNotice updateAvailable(bool updateAvailable);

  UpdateNotice url(String? url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateNotice(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateNotice(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateNotice call({
    String current,
    String? latest,
    bool updateAvailable,
    String? url,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateNotice.copyWith(...)` or call `instanceOfUpdateNotice.copyWith.fieldName(value)` for a single field.
class _$UpdateNoticeCWProxyImpl implements _$UpdateNoticeCWProxy {
  const _$UpdateNoticeCWProxyImpl(this._value);

  final UpdateNotice _value;

  @override
  UpdateNotice current(String current) => call(current: current);

  @override
  UpdateNotice latest(String? latest) => call(latest: latest);

  @override
  UpdateNotice updateAvailable(bool updateAvailable) =>
      call(updateAvailable: updateAvailable);

  @override
  UpdateNotice url(String? url) => call(url: url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateNotice(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateNotice(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateNotice call({
    Object? current = const $CopyWithPlaceholder(),
    Object? latest = const $CopyWithPlaceholder(),
    Object? updateAvailable = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
  }) {
    return UpdateNotice(
      current: current == const $CopyWithPlaceholder() || current == null
          ? _value.current
          // ignore: cast_nullable_to_non_nullable
          : current as String,
      latest: latest == const $CopyWithPlaceholder()
          ? _value.latest
          // ignore: cast_nullable_to_non_nullable
          : latest as String?,
      updateAvailable:
          updateAvailable == const $CopyWithPlaceholder() ||
              updateAvailable == null
          ? _value.updateAvailable
          // ignore: cast_nullable_to_non_nullable
          : updateAvailable as bool,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
    );
  }
}

extension $UpdateNoticeCopyWith on UpdateNotice {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateNotice.copyWith(...)` or `instanceOfUpdateNotice.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateNoticeCWProxy get copyWith => _$UpdateNoticeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateNotice _$UpdateNoticeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateNotice', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['current', 'latest', 'update_available', 'url'],
      );
      final val = UpdateNotice(
        current: $checkedConvert('current', (v) => v as String),
        latest: $checkedConvert('latest', (v) => v as String?),
        updateAvailable: $checkedConvert('update_available', (v) => v as bool),
        url: $checkedConvert('url', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'updateAvailable': 'update_available'});

Map<String, dynamic> _$UpdateNoticeToJson(UpdateNotice instance) =>
    <String, dynamic>{
      'current': instance.current,
      'latest': instance.latest,
      'update_available': instance.updateAvailable,
      'url': instance.url,
    };
