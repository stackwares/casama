// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comp_code_preview.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CompCodePreviewCWProxy {
  CompCodePreview planCode(String planCode);

  CompCodePreview planName(String planName);

  CompCodePreview months(int months);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CompCodePreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CompCodePreview(...).copyWith(id: 12, name: "My name")
  /// ```
  CompCodePreview call({String planCode, String planName, int months});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCompCodePreview.copyWith(...)` or call `instanceOfCompCodePreview.copyWith.fieldName(value)` for a single field.
class _$CompCodePreviewCWProxyImpl implements _$CompCodePreviewCWProxy {
  const _$CompCodePreviewCWProxyImpl(this._value);

  final CompCodePreview _value;

  @override
  CompCodePreview planCode(String planCode) => call(planCode: planCode);

  @override
  CompCodePreview planName(String planName) => call(planName: planName);

  @override
  CompCodePreview months(int months) => call(months: months);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CompCodePreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CompCodePreview(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CompCodePreview call({
    Object? planCode = const $CopyWithPlaceholder(),
    Object? planName = const $CopyWithPlaceholder(),
    Object? months = const $CopyWithPlaceholder(),
  }) {
    return CompCodePreview(
      planCode: planCode == const $CopyWithPlaceholder() || planCode == null
          ? _value.planCode
          // ignore: cast_nullable_to_non_nullable
          : planCode as String,
      planName: planName == const $CopyWithPlaceholder() || planName == null
          ? _value.planName
          // ignore: cast_nullable_to_non_nullable
          : planName as String,
      months: months == const $CopyWithPlaceholder() || months == null
          ? _value.months
          // ignore: cast_nullable_to_non_nullable
          : months as int,
    );
  }
}

extension $CompCodePreviewCopyWith on CompCodePreview {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCompCodePreview.copyWith(...)` or `instanceOfCompCodePreview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CompCodePreviewCWProxy get copyWith => _$CompCodePreviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompCodePreview _$CompCodePreviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CompCodePreview', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['plan_code', 'plan_name', 'months'],
      );
      final val = CompCodePreview(
        planCode: $checkedConvert('plan_code', (v) => v as String),
        planName: $checkedConvert('plan_name', (v) => v as String),
        months: $checkedConvert('months', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'planCode': 'plan_code', 'planName': 'plan_name'});

Map<String, dynamic> _$CompCodePreviewToJson(CompCodePreview instance) =>
    <String, dynamic>{
      'plan_code': instance.planCode,
      'plan_name': instance.planName,
      'months': instance.months,
    };
