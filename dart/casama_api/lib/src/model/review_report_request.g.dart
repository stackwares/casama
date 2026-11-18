// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_report_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReviewReportRequestCWProxy {
  ReviewReportRequest decision(ReviewReportRequestDecisionEnum decision);

  ReviewReportRequest suspendWorkspace(bool? suspendWorkspace);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReviewReportRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReviewReportRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ReviewReportRequest call({
    ReviewReportRequestDecisionEnum decision,
    bool? suspendWorkspace,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReviewReportRequest.copyWith(...)` or call `instanceOfReviewReportRequest.copyWith.fieldName(value)` for a single field.
class _$ReviewReportRequestCWProxyImpl implements _$ReviewReportRequestCWProxy {
  const _$ReviewReportRequestCWProxyImpl(this._value);

  final ReviewReportRequest _value;

  @override
  ReviewReportRequest decision(ReviewReportRequestDecisionEnum decision) =>
      call(decision: decision);

  @override
  ReviewReportRequest suspendWorkspace(bool? suspendWorkspace) =>
      call(suspendWorkspace: suspendWorkspace);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReviewReportRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReviewReportRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReviewReportRequest call({
    Object? decision = const $CopyWithPlaceholder(),
    Object? suspendWorkspace = const $CopyWithPlaceholder(),
  }) {
    return ReviewReportRequest(
      decision: decision == const $CopyWithPlaceholder() || decision == null
          ? _value.decision
          // ignore: cast_nullable_to_non_nullable
          : decision as ReviewReportRequestDecisionEnum,
      suspendWorkspace: suspendWorkspace == const $CopyWithPlaceholder()
          ? _value.suspendWorkspace
          // ignore: cast_nullable_to_non_nullable
          : suspendWorkspace as bool?,
    );
  }
}

extension $ReviewReportRequestCopyWith on ReviewReportRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReviewReportRequest.copyWith(...)` or `instanceOfReviewReportRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReviewReportRequestCWProxy get copyWith =>
      _$ReviewReportRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewReportRequest _$ReviewReportRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReviewReportRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['decision']);
      final val = ReviewReportRequest(
        decision: $checkedConvert(
          'decision',
          (v) => $enumDecode(_$ReviewReportRequestDecisionEnumEnumMap, v),
        ),
        suspendWorkspace: $checkedConvert(
          'suspend_workspace',
          (v) => v as bool?,
        ),
      );
      return val;
    }, fieldKeyMap: const {'suspendWorkspace': 'suspend_workspace'});

Map<String, dynamic> _$ReviewReportRequestToJson(
  ReviewReportRequest instance,
) => <String, dynamic>{
  'decision': _$ReviewReportRequestDecisionEnumEnumMap[instance.decision]!,
  'suspend_workspace': ?instance.suspendWorkspace,
};

const _$ReviewReportRequestDecisionEnumEnumMap = {
  ReviewReportRequestDecisionEnum.actioned: 'actioned',
  ReviewReportRequestDecisionEnum.dismissed: 'dismissed',
};
