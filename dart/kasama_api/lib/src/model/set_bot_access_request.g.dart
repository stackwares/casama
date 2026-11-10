// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_bot_access_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetBotAccessRequestCWProxy {
  SetBotAccessRequest visibility(SetBotAccessRequestVisibilityEnum visibility);

  SetBotAccessRequest entries(List<SetBotAccessRequestEntriesInner> entries);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetBotAccessRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetBotAccessRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetBotAccessRequest call({
    SetBotAccessRequestVisibilityEnum visibility,
    List<SetBotAccessRequestEntriesInner> entries,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetBotAccessRequest.copyWith(...)` or call `instanceOfSetBotAccessRequest.copyWith.fieldName(value)` for a single field.
class _$SetBotAccessRequestCWProxyImpl implements _$SetBotAccessRequestCWProxy {
  const _$SetBotAccessRequestCWProxyImpl(this._value);

  final SetBotAccessRequest _value;

  @override
  SetBotAccessRequest visibility(
    SetBotAccessRequestVisibilityEnum visibility,
  ) => call(visibility: visibility);

  @override
  SetBotAccessRequest entries(List<SetBotAccessRequestEntriesInner> entries) =>
      call(entries: entries);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetBotAccessRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetBotAccessRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetBotAccessRequest call({
    Object? visibility = const $CopyWithPlaceholder(),
    Object? entries = const $CopyWithPlaceholder(),
  }) {
    return SetBotAccessRequest(
      visibility:
          visibility == const $CopyWithPlaceholder() || visibility == null
          ? _value.visibility
          // ignore: cast_nullable_to_non_nullable
          : visibility as SetBotAccessRequestVisibilityEnum,
      entries: entries == const $CopyWithPlaceholder() || entries == null
          ? _value.entries
          // ignore: cast_nullable_to_non_nullable
          : entries as List<SetBotAccessRequestEntriesInner>,
    );
  }
}

extension $SetBotAccessRequestCopyWith on SetBotAccessRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetBotAccessRequest.copyWith(...)` or `instanceOfSetBotAccessRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetBotAccessRequestCWProxy get copyWith =>
      _$SetBotAccessRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetBotAccessRequest _$SetBotAccessRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SetBotAccessRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['visibility', 'entries']);
      final val = SetBotAccessRequest(
        visibility: $checkedConvert(
          'visibility',
          (v) => $enumDecode(_$SetBotAccessRequestVisibilityEnumEnumMap, v),
        ),
        entries: $checkedConvert(
          'entries',
          (v) => (v as List<dynamic>)
              .map(
                (e) => SetBotAccessRequestEntriesInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SetBotAccessRequestToJson(
  SetBotAccessRequest instance,
) => <String, dynamic>{
  'visibility':
      _$SetBotAccessRequestVisibilityEnumEnumMap[instance.visibility]!,
  'entries': instance.entries.map((e) => e.toJson()).toList(),
};

const _$SetBotAccessRequestVisibilityEnumEnumMap = {
  SetBotAccessRequestVisibilityEnum.private: 'private',
  SetBotAccessRequestVisibilityEnum.team: 'team',
};
