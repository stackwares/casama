// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_mention_ref.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppMentionRefCWProxy {
  AppMentionRef integrationId(String integrationId);

  AppMentionRef toolkit(String? toolkit);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppMentionRef(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppMentionRef(...).copyWith(id: 12, name: "My name")
  /// ```
  AppMentionRef call({String integrationId, String? toolkit});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAppMentionRef.copyWith(...)` or call `instanceOfAppMentionRef.copyWith.fieldName(value)` for a single field.
class _$AppMentionRefCWProxyImpl implements _$AppMentionRefCWProxy {
  const _$AppMentionRefCWProxyImpl(this._value);

  final AppMentionRef _value;

  @override
  AppMentionRef integrationId(String integrationId) =>
      call(integrationId: integrationId);

  @override
  AppMentionRef toolkit(String? toolkit) => call(toolkit: toolkit);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppMentionRef(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppMentionRef(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AppMentionRef call({
    Object? integrationId = const $CopyWithPlaceholder(),
    Object? toolkit = const $CopyWithPlaceholder(),
  }) {
    return AppMentionRef(
      integrationId:
          integrationId == const $CopyWithPlaceholder() || integrationId == null
          ? _value.integrationId
          // ignore: cast_nullable_to_non_nullable
          : integrationId as String,
      toolkit: toolkit == const $CopyWithPlaceholder()
          ? _value.toolkit
          // ignore: cast_nullable_to_non_nullable
          : toolkit as String?,
    );
  }
}

extension $AppMentionRefCopyWith on AppMentionRef {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAppMentionRef.copyWith(...)` or `instanceOfAppMentionRef.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppMentionRefCWProxy get copyWith => _$AppMentionRefCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppMentionRef _$AppMentionRefFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AppMentionRef', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['integration_id']);
      final val = AppMentionRef(
        integrationId: $checkedConvert('integration_id', (v) => v as String),
        toolkit: $checkedConvert('toolkit', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'integrationId': 'integration_id'});

Map<String, dynamic> _$AppMentionRefToJson(AppMentionRef instance) =>
    <String, dynamic>{
      'integration_id': instance.integrationId,
      'toolkit': ?instance.toolkit,
    };
