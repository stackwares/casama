// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_handoff.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchHandoffCWProxy {
  WatchHandoff link(String link);

  WatchHandoff title(String title);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchHandoff(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchHandoff(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchHandoff call({String link, String title});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchHandoff.copyWith(...)` or call `instanceOfWatchHandoff.copyWith.fieldName(value)` for a single field.
class _$WatchHandoffCWProxyImpl implements _$WatchHandoffCWProxy {
  const _$WatchHandoffCWProxyImpl(this._value);

  final WatchHandoff _value;

  @override
  WatchHandoff link(String link) => call(link: link);

  @override
  WatchHandoff title(String title) => call(title: title);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchHandoff(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchHandoff(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchHandoff call({
    Object? link = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
  }) {
    return WatchHandoff(
      link: link == const $CopyWithPlaceholder() || link == null
          ? _value.link
          // ignore: cast_nullable_to_non_nullable
          : link as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
    );
  }
}

extension $WatchHandoffCopyWith on WatchHandoff {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchHandoff.copyWith(...)` or `instanceOfWatchHandoff.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchHandoffCWProxy get copyWith => _$WatchHandoffCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchHandoff _$WatchHandoffFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WatchHandoff', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['link', 'title']);
      final val = WatchHandoff(
        link: $checkedConvert('link', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$WatchHandoffToJson(WatchHandoff instance) =>
    <String, dynamic>{'link': instance.link, 'title': instance.title};
