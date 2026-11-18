// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_approval_decision.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryApprovalDecisionCWProxy {
  GalleryApprovalDecision decision(
    GalleryApprovalDecisionDecisionEnum decision,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryApprovalDecision(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryApprovalDecision(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryApprovalDecision call({GalleryApprovalDecisionDecisionEnum decision});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryApprovalDecision.copyWith(...)` or call `instanceOfGalleryApprovalDecision.copyWith.fieldName(value)` for a single field.
class _$GalleryApprovalDecisionCWProxyImpl
    implements _$GalleryApprovalDecisionCWProxy {
  const _$GalleryApprovalDecisionCWProxyImpl(this._value);

  final GalleryApprovalDecision _value;

  @override
  GalleryApprovalDecision decision(
    GalleryApprovalDecisionDecisionEnum decision,
  ) => call(decision: decision);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryApprovalDecision(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryApprovalDecision(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryApprovalDecision call({
    Object? decision = const $CopyWithPlaceholder(),
  }) {
    return GalleryApprovalDecision(
      decision: decision == const $CopyWithPlaceholder() || decision == null
          ? _value.decision
          // ignore: cast_nullable_to_non_nullable
          : decision as GalleryApprovalDecisionDecisionEnum,
    );
  }
}

extension $GalleryApprovalDecisionCopyWith on GalleryApprovalDecision {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryApprovalDecision.copyWith(...)` or `instanceOfGalleryApprovalDecision.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryApprovalDecisionCWProxy get copyWith =>
      _$GalleryApprovalDecisionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryApprovalDecision _$GalleryApprovalDecisionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GalleryApprovalDecision', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['decision']);
  final val = GalleryApprovalDecision(
    decision: $checkedConvert(
      'decision',
      (v) => $enumDecode(_$GalleryApprovalDecisionDecisionEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$GalleryApprovalDecisionToJson(
  GalleryApprovalDecision instance,
) => <String, dynamic>{
  'decision': _$GalleryApprovalDecisionDecisionEnumEnumMap[instance.decision]!,
};

const _$GalleryApprovalDecisionDecisionEnumEnumMap = {
  GalleryApprovalDecisionDecisionEnum.approved: 'approved',
  GalleryApprovalDecisionDecisionEnum.denied: 'denied',
};
