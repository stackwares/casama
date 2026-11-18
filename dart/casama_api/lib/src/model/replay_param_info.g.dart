// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'replay_param_info.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReplayParamInfoCWProxy {
  ReplayParamInfo name(String name);

  ReplayParamInfo description(String? description);

  ReplayParamInfo default_(String? default_);

  ReplayParamInfo secret(bool? secret);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReplayParamInfo(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReplayParamInfo(...).copyWith(id: 12, name: "My name")
  /// ```
  ReplayParamInfo call({
    String name,
    String? description,
    String? default_,
    bool? secret,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReplayParamInfo.copyWith(...)` or call `instanceOfReplayParamInfo.copyWith.fieldName(value)` for a single field.
class _$ReplayParamInfoCWProxyImpl implements _$ReplayParamInfoCWProxy {
  const _$ReplayParamInfoCWProxyImpl(this._value);

  final ReplayParamInfo _value;

  @override
  ReplayParamInfo name(String name) => call(name: name);

  @override
  ReplayParamInfo description(String? description) =>
      call(description: description);

  @override
  ReplayParamInfo default_(String? default_) => call(default_: default_);

  @override
  ReplayParamInfo secret(bool? secret) => call(secret: secret);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReplayParamInfo(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReplayParamInfo(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReplayParamInfo call({
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? default_ = const $CopyWithPlaceholder(),
    Object? secret = const $CopyWithPlaceholder(),
  }) {
    return ReplayParamInfo(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String?,
      default_: default_ == const $CopyWithPlaceholder()
          ? _value.default_
          // ignore: cast_nullable_to_non_nullable
          : default_ as String?,
      secret: secret == const $CopyWithPlaceholder()
          ? _value.secret
          // ignore: cast_nullable_to_non_nullable
          : secret as bool?,
    );
  }
}

extension $ReplayParamInfoCopyWith on ReplayParamInfo {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReplayParamInfo.copyWith(...)` or `instanceOfReplayParamInfo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReplayParamInfoCWProxy get copyWith => _$ReplayParamInfoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReplayParamInfo _$ReplayParamInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReplayParamInfo', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name']);
      final val = ReplayParamInfo(
        name: $checkedConvert('name', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String?),
        default_: $checkedConvert('default', (v) => v as String?),
        secret: $checkedConvert('secret', (v) => v as bool?),
      );
      return val;
    }, fieldKeyMap: const {'default_': 'default'});

Map<String, dynamic> _$ReplayParamInfoToJson(ReplayParamInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': ?instance.description,
      'default': ?instance.default_,
      'secret': ?instance.secret,
    };
