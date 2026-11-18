// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_teach_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SaveTeachResponseCWProxy {
  SaveTeachResponse skillId(String skillId);

  SaveTeachResponse conversationId(String? conversationId);

  SaveTeachResponse runId(String? runId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveTeachResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveTeachResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  SaveTeachResponse call({
    String skillId,
    String? conversationId,
    String? runId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSaveTeachResponse.copyWith(...)` or call `instanceOfSaveTeachResponse.copyWith.fieldName(value)` for a single field.
class _$SaveTeachResponseCWProxyImpl implements _$SaveTeachResponseCWProxy {
  const _$SaveTeachResponseCWProxyImpl(this._value);

  final SaveTeachResponse _value;

  @override
  SaveTeachResponse skillId(String skillId) => call(skillId: skillId);

  @override
  SaveTeachResponse conversationId(String? conversationId) =>
      call(conversationId: conversationId);

  @override
  SaveTeachResponse runId(String? runId) => call(runId: runId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveTeachResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveTeachResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SaveTeachResponse call({
    Object? skillId = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
  }) {
    return SaveTeachResponse(
      skillId: skillId == const $CopyWithPlaceholder() || skillId == null
          ? _value.skillId
          // ignore: cast_nullable_to_non_nullable
          : skillId as String,
      conversationId: conversationId == const $CopyWithPlaceholder()
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String?,
      runId: runId == const $CopyWithPlaceholder()
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String?,
    );
  }
}

extension $SaveTeachResponseCopyWith on SaveTeachResponse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSaveTeachResponse.copyWith(...)` or `instanceOfSaveTeachResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SaveTeachResponseCWProxy get copyWith =>
      _$SaveTeachResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveTeachResponse _$SaveTeachResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SaveTeachResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['skill_id', 'conversation_id', 'run_id'],
        );
        final val = SaveTeachResponse(
          skillId: $checkedConvert('skill_id', (v) => v as String),
          conversationId: $checkedConvert(
            'conversation_id',
            (v) => v as String?,
          ),
          runId: $checkedConvert('run_id', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'skillId': 'skill_id',
        'conversationId': 'conversation_id',
        'runId': 'run_id',
      },
    );

Map<String, dynamic> _$SaveTeachResponseToJson(SaveTeachResponse instance) =>
    <String, dynamic>{
      'skill_id': instance.skillId,
      'conversation_id': instance.conversationId,
      'run_id': instance.runId,
    };
