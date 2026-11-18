// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_user_facts_request_items_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AddUserFactsRequestItemsInnerCWProxy {
  AddUserFactsRequestItemsInner kind(
    AddUserFactsRequestItemsInnerKindEnum? kind,
  );

  AddUserFactsRequestItemsInner content(String content);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AddUserFactsRequestItemsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AddUserFactsRequestItemsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  AddUserFactsRequestItemsInner call({
    AddUserFactsRequestItemsInnerKindEnum? kind,
    String content,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAddUserFactsRequestItemsInner.copyWith(...)` or call `instanceOfAddUserFactsRequestItemsInner.copyWith.fieldName(value)` for a single field.
class _$AddUserFactsRequestItemsInnerCWProxyImpl
    implements _$AddUserFactsRequestItemsInnerCWProxy {
  const _$AddUserFactsRequestItemsInnerCWProxyImpl(this._value);

  final AddUserFactsRequestItemsInner _value;

  @override
  AddUserFactsRequestItemsInner kind(
    AddUserFactsRequestItemsInnerKindEnum? kind,
  ) => call(kind: kind);

  @override
  AddUserFactsRequestItemsInner content(String content) =>
      call(content: content);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AddUserFactsRequestItemsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AddUserFactsRequestItemsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AddUserFactsRequestItemsInner call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? content = const $CopyWithPlaceholder(),
  }) {
    return AddUserFactsRequestItemsInner(
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as AddUserFactsRequestItemsInnerKindEnum?,
      content: content == const $CopyWithPlaceholder() || content == null
          ? _value.content
          // ignore: cast_nullable_to_non_nullable
          : content as String,
    );
  }
}

extension $AddUserFactsRequestItemsInnerCopyWith
    on AddUserFactsRequestItemsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAddUserFactsRequestItemsInner.copyWith(...)` or `instanceOfAddUserFactsRequestItemsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AddUserFactsRequestItemsInnerCWProxy get copyWith =>
      _$AddUserFactsRequestItemsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddUserFactsRequestItemsInner _$AddUserFactsRequestItemsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AddUserFactsRequestItemsInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['content']);
  final val = AddUserFactsRequestItemsInner(
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecodeNullable(
        _$AddUserFactsRequestItemsInnerKindEnumEnumMap,
        v,
      ),
    ),
    content: $checkedConvert('content', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$AddUserFactsRequestItemsInnerToJson(
  AddUserFactsRequestItemsInner instance,
) => <String, dynamic>{
  'kind': ?_$AddUserFactsRequestItemsInnerKindEnumEnumMap[instance.kind],
  'content': instance.content,
};

const _$AddUserFactsRequestItemsInnerKindEnumEnumMap = {
  AddUserFactsRequestItemsInnerKindEnum.fact: 'fact',
  AddUserFactsRequestItemsInnerKindEnum.preference: 'preference',
};
