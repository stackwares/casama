// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'for_you_approval.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ForYouApprovalCWProxy {
  ForYouApproval id(String id);

  ForYouApproval botId(String botId);

  ForYouApproval summary(String summary);

  ForYouApproval risk(String risk);

  ForYouApproval createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ForYouApproval(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ForYouApproval(...).copyWith(id: 12, name: "My name")
  /// ```
  ForYouApproval call({
    String id,
    String botId,
    String summary,
    String risk,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfForYouApproval.copyWith(...)` or call `instanceOfForYouApproval.copyWith.fieldName(value)` for a single field.
class _$ForYouApprovalCWProxyImpl implements _$ForYouApprovalCWProxy {
  const _$ForYouApprovalCWProxyImpl(this._value);

  final ForYouApproval _value;

  @override
  ForYouApproval id(String id) => call(id: id);

  @override
  ForYouApproval botId(String botId) => call(botId: botId);

  @override
  ForYouApproval summary(String summary) => call(summary: summary);

  @override
  ForYouApproval risk(String risk) => call(risk: risk);

  @override
  ForYouApproval createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ForYouApproval(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ForYouApproval(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ForYouApproval call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? summary = const $CopyWithPlaceholder(),
    Object? risk = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return ForYouApproval(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      summary: summary == const $CopyWithPlaceholder() || summary == null
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as String,
      risk: risk == const $CopyWithPlaceholder() || risk == null
          ? _value.risk
          // ignore: cast_nullable_to_non_nullable
          : risk as String,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $ForYouApprovalCopyWith on ForYouApproval {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfForYouApproval.copyWith(...)` or `instanceOfForYouApproval.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ForYouApprovalCWProxy get copyWith => _$ForYouApprovalCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForYouApproval _$ForYouApprovalFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ForYouApproval', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['id', 'bot_id', 'summary', 'risk', 'created_at'],
      );
      final val = ForYouApproval(
        id: $checkedConvert('id', (v) => v as String),
        botId: $checkedConvert('bot_id', (v) => v as String),
        summary: $checkedConvert('summary', (v) => v as String),
        risk: $checkedConvert('risk', (v) => v as String),
        createdAt: $checkedConvert(
          'created_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'botId': 'bot_id', 'createdAt': 'created_at'});

Map<String, dynamic> _$ForYouApprovalToJson(ForYouApproval instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bot_id': instance.botId,
      'summary': instance.summary,
      'risk': instance.risk,
      'created_at': instance.createdAt.toIso8601String(),
    };
