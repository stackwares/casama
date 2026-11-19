// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paste_bot_import_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PasteBotImportRequestCWProxy {
  PasteBotImportRequest orgId(String orgId);

  PasteBotImportRequest source_(PasteImportSource source_);

  PasteBotImportRequest text(String text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PasteBotImportRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PasteBotImportRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  PasteBotImportRequest call({
    String orgId,
    PasteImportSource source_,
    String text,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPasteBotImportRequest.copyWith(...)` or call `instanceOfPasteBotImportRequest.copyWith.fieldName(value)` for a single field.
class _$PasteBotImportRequestCWProxyImpl
    implements _$PasteBotImportRequestCWProxy {
  const _$PasteBotImportRequestCWProxyImpl(this._value);

  final PasteBotImportRequest _value;

  @override
  PasteBotImportRequest orgId(String orgId) => call(orgId: orgId);

  @override
  PasteBotImportRequest source_(PasteImportSource source_) =>
      call(source_: source_);

  @override
  PasteBotImportRequest text(String text) => call(text: text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PasteBotImportRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PasteBotImportRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PasteBotImportRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return PasteBotImportRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as PasteImportSource,
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $PasteBotImportRequestCopyWith on PasteBotImportRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPasteBotImportRequest.copyWith(...)` or `instanceOfPasteBotImportRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PasteBotImportRequestCWProxy get copyWith =>
      _$PasteBotImportRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PasteBotImportRequest _$PasteBotImportRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PasteBotImportRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['org_id', 'source', 'text']);
  final val = PasteBotImportRequest(
    orgId: $checkedConvert('org_id', (v) => v as String),
    source_: $checkedConvert(
      'source',
      (v) => $enumDecode(_$PasteImportSourceEnumMap, v),
    ),
    text: $checkedConvert('text', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'orgId': 'org_id', 'source_': 'source'});

Map<String, dynamic> _$PasteBotImportRequestToJson(
  PasteBotImportRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'source': _$PasteImportSourceEnumMap[instance.source_]!,
  'text': instance.text,
};

const _$PasteImportSourceEnumMap = {
  PasteImportSource.grokBot: 'grok_bot',
  PasteImportSource.muse: 'muse',
  PasteImportSource.dots: 'dots',
  PasteImportSource.duet: 'duet',
  PasteImportSource.hark: 'hark',
  PasteImportSource.instinct: 'instinct',
  PasteImportSource.other: 'other',
};
