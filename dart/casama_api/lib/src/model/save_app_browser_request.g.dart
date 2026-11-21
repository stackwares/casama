// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_app_browser_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SaveAppBrowserRequestCWProxy {
  SaveAppBrowserRequest stage(SaveAppBrowserRequestStageEnum stage);

  SaveAppBrowserRequest testers(List<String>? testers);

  SaveAppBrowserRequest reasons(SaveAppBrowserRequestReasons? reasons);

  SaveAppBrowserRequest systems(
    List<SaveAppBrowserRequestSystemsEnum>? systems,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveAppBrowserRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveAppBrowserRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SaveAppBrowserRequest call({
    SaveAppBrowserRequestStageEnum stage,
    List<String>? testers,
    SaveAppBrowserRequestReasons? reasons,
    List<SaveAppBrowserRequestSystemsEnum>? systems,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSaveAppBrowserRequest.copyWith(...)` or call `instanceOfSaveAppBrowserRequest.copyWith.fieldName(value)` for a single field.
class _$SaveAppBrowserRequestCWProxyImpl
    implements _$SaveAppBrowserRequestCWProxy {
  const _$SaveAppBrowserRequestCWProxyImpl(this._value);

  final SaveAppBrowserRequest _value;

  @override
  SaveAppBrowserRequest stage(SaveAppBrowserRequestStageEnum stage) =>
      call(stage: stage);

  @override
  SaveAppBrowserRequest testers(List<String>? testers) =>
      call(testers: testers);

  @override
  SaveAppBrowserRequest reasons(SaveAppBrowserRequestReasons? reasons) =>
      call(reasons: reasons);

  @override
  SaveAppBrowserRequest systems(
    List<SaveAppBrowserRequestSystemsEnum>? systems,
  ) => call(systems: systems);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveAppBrowserRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveAppBrowserRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SaveAppBrowserRequest call({
    Object? stage = const $CopyWithPlaceholder(),
    Object? testers = const $CopyWithPlaceholder(),
    Object? reasons = const $CopyWithPlaceholder(),
    Object? systems = const $CopyWithPlaceholder(),
  }) {
    return SaveAppBrowserRequest(
      stage: stage == const $CopyWithPlaceholder() || stage == null
          ? _value.stage
          // ignore: cast_nullable_to_non_nullable
          : stage as SaveAppBrowserRequestStageEnum,
      testers: testers == const $CopyWithPlaceholder()
          ? _value.testers
          // ignore: cast_nullable_to_non_nullable
          : testers as List<String>?,
      reasons: reasons == const $CopyWithPlaceholder()
          ? _value.reasons
          // ignore: cast_nullable_to_non_nullable
          : reasons as SaveAppBrowserRequestReasons?,
      systems: systems == const $CopyWithPlaceholder()
          ? _value.systems
          // ignore: cast_nullable_to_non_nullable
          : systems as List<SaveAppBrowserRequestSystemsEnum>?,
    );
  }
}

extension $SaveAppBrowserRequestCopyWith on SaveAppBrowserRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSaveAppBrowserRequest.copyWith(...)` or `instanceOfSaveAppBrowserRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SaveAppBrowserRequestCWProxy get copyWith =>
      _$SaveAppBrowserRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveAppBrowserRequest _$SaveAppBrowserRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SaveAppBrowserRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['stage']);
  final val = SaveAppBrowserRequest(
    stage: $checkedConvert(
      'stage',
      (v) => $enumDecode(_$SaveAppBrowserRequestStageEnumEnumMap, v),
    ),
    testers: $checkedConvert(
      'testers',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
    ),
    reasons: $checkedConvert(
      'reasons',
      (v) => v == null
          ? null
          : SaveAppBrowserRequestReasons.fromJson(v as Map<String, dynamic>),
    ),
    systems: $checkedConvert(
      'systems',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => $enumDecode(_$SaveAppBrowserRequestSystemsEnumEnumMap, e),
          )
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$SaveAppBrowserRequestToJson(
  SaveAppBrowserRequest instance,
) => <String, dynamic>{
  'stage': _$SaveAppBrowserRequestStageEnumEnumMap[instance.stage]!,
  'testers': ?instance.testers,
  'reasons': ?instance.reasons?.toJson(),
  'systems': ?instance.systems
      ?.map((e) => _$SaveAppBrowserRequestSystemsEnumEnumMap[e]!)
      .toList(),
};

const _$SaveAppBrowserRequestStageEnumEnumMap = {
  SaveAppBrowserRequestStageEnum.off: 'off',
  SaveAppBrowserRequestStageEnum.testers: 'testers',
  SaveAppBrowserRequestStageEnum.on_: 'on',
};

const _$SaveAppBrowserRequestSystemsEnumEnumMap = {
  SaveAppBrowserRequestSystemsEnum.ios: 'ios',
  SaveAppBrowserRequestSystemsEnum.android: 'android',
};
