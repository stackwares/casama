// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_policy.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryPolicyCWProxy {
  GalleryPolicy mode(GalleryPolicyModeEnum mode);

  GalleryPolicy allow(List<String> allow);

  GalleryPolicy block(List<String> block);

  GalleryPolicy approvalFor(List<GalleryPolicyApprovalForEnum> approvalFor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryPolicy(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryPolicy(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryPolicy call({
    GalleryPolicyModeEnum mode,
    List<String> allow,
    List<String> block,
    List<GalleryPolicyApprovalForEnum> approvalFor,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryPolicy.copyWith(...)` or call `instanceOfGalleryPolicy.copyWith.fieldName(value)` for a single field.
class _$GalleryPolicyCWProxyImpl implements _$GalleryPolicyCWProxy {
  const _$GalleryPolicyCWProxyImpl(this._value);

  final GalleryPolicy _value;

  @override
  GalleryPolicy mode(GalleryPolicyModeEnum mode) => call(mode: mode);

  @override
  GalleryPolicy allow(List<String> allow) => call(allow: allow);

  @override
  GalleryPolicy block(List<String> block) => call(block: block);

  @override
  GalleryPolicy approvalFor(List<GalleryPolicyApprovalForEnum> approvalFor) =>
      call(approvalFor: approvalFor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryPolicy(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryPolicy(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryPolicy call({
    Object? mode = const $CopyWithPlaceholder(),
    Object? allow = const $CopyWithPlaceholder(),
    Object? block = const $CopyWithPlaceholder(),
    Object? approvalFor = const $CopyWithPlaceholder(),
  }) {
    return GalleryPolicy(
      mode: mode == const $CopyWithPlaceholder() || mode == null
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as GalleryPolicyModeEnum,
      allow: allow == const $CopyWithPlaceholder() || allow == null
          ? _value.allow
          // ignore: cast_nullable_to_non_nullable
          : allow as List<String>,
      block: block == const $CopyWithPlaceholder() || block == null
          ? _value.block
          // ignore: cast_nullable_to_non_nullable
          : block as List<String>,
      approvalFor:
          approvalFor == const $CopyWithPlaceholder() || approvalFor == null
          ? _value.approvalFor
          // ignore: cast_nullable_to_non_nullable
          : approvalFor as List<GalleryPolicyApprovalForEnum>,
    );
  }
}

extension $GalleryPolicyCopyWith on GalleryPolicy {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryPolicy.copyWith(...)` or `instanceOfGalleryPolicy.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryPolicyCWProxy get copyWith => _$GalleryPolicyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryPolicy _$GalleryPolicyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryPolicy', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['mode', 'allow', 'block', 'approval_for'],
      );
      final val = GalleryPolicy(
        mode: $checkedConvert(
          'mode',
          (v) => $enumDecode(_$GalleryPolicyModeEnumEnumMap, v),
        ),
        allow: $checkedConvert(
          'allow',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        block: $checkedConvert(
          'block',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        approvalFor: $checkedConvert(
          'approval_for',
          (v) => (v as List<dynamic>)
              .map((e) => $enumDecode(_$GalleryPolicyApprovalForEnumEnumMap, e))
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'approvalFor': 'approval_for'});

Map<String, dynamic> _$GalleryPolicyToJson(GalleryPolicy instance) =>
    <String, dynamic>{
      'mode': _$GalleryPolicyModeEnumEnumMap[instance.mode]!,
      'allow': instance.allow,
      'block': instance.block,
      'approval_for': instance.approvalFor
          .map((e) => _$GalleryPolicyApprovalForEnumEnumMap[e]!)
          .toList(),
    };

const _$GalleryPolicyModeEnumEnumMap = {
  GalleryPolicyModeEnum.open: 'open',
  GalleryPolicyModeEnum.approval: 'approval',
  GalleryPolicyModeEnum.allowlist: 'allowlist',
};

const _$GalleryPolicyApprovalForEnumEnumMap = {
  GalleryPolicyApprovalForEnum.runsCode: 'runs_code',
  GalleryPolicyApprovalForEnum.apps: 'apps',
  GalleryPolicyApprovalForEnum.all: 'all',
};
