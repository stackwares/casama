// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_bot_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ImportBotRequestCWProxy {
  ImportBotRequest orgId(String orgId);

  ImportBotRequest template(BotTemplateFile template);

  ImportBotRequest credentialId(String credentialId);

  ImportBotRequest model(String model);

  ImportBotRequest includeMemories(bool? includeMemories);

  ImportBotRequest includeRoutines(bool? includeRoutines);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ImportBotRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ImportBotRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ImportBotRequest call({
    String orgId,
    BotTemplateFile template,
    String credentialId,
    String model,
    bool? includeMemories,
    bool? includeRoutines,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfImportBotRequest.copyWith(...)` or call `instanceOfImportBotRequest.copyWith.fieldName(value)` for a single field.
class _$ImportBotRequestCWProxyImpl implements _$ImportBotRequestCWProxy {
  const _$ImportBotRequestCWProxyImpl(this._value);

  final ImportBotRequest _value;

  @override
  ImportBotRequest orgId(String orgId) => call(orgId: orgId);

  @override
  ImportBotRequest template(BotTemplateFile template) =>
      call(template: template);

  @override
  ImportBotRequest credentialId(String credentialId) =>
      call(credentialId: credentialId);

  @override
  ImportBotRequest model(String model) => call(model: model);

  @override
  ImportBotRequest includeMemories(bool? includeMemories) =>
      call(includeMemories: includeMemories);

  @override
  ImportBotRequest includeRoutines(bool? includeRoutines) =>
      call(includeRoutines: includeRoutines);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ImportBotRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ImportBotRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ImportBotRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? template = const $CopyWithPlaceholder(),
    Object? credentialId = const $CopyWithPlaceholder(),
    Object? model = const $CopyWithPlaceholder(),
    Object? includeMemories = const $CopyWithPlaceholder(),
    Object? includeRoutines = const $CopyWithPlaceholder(),
  }) {
    return ImportBotRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      template: template == const $CopyWithPlaceholder() || template == null
          ? _value.template
          // ignore: cast_nullable_to_non_nullable
          : template as BotTemplateFile,
      credentialId:
          credentialId == const $CopyWithPlaceholder() || credentialId == null
          ? _value.credentialId
          // ignore: cast_nullable_to_non_nullable
          : credentialId as String,
      model: model == const $CopyWithPlaceholder() || model == null
          ? _value.model
          // ignore: cast_nullable_to_non_nullable
          : model as String,
      includeMemories: includeMemories == const $CopyWithPlaceholder()
          ? _value.includeMemories
          // ignore: cast_nullable_to_non_nullable
          : includeMemories as bool?,
      includeRoutines: includeRoutines == const $CopyWithPlaceholder()
          ? _value.includeRoutines
          // ignore: cast_nullable_to_non_nullable
          : includeRoutines as bool?,
    );
  }
}

extension $ImportBotRequestCopyWith on ImportBotRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfImportBotRequest.copyWith(...)` or `instanceOfImportBotRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ImportBotRequestCWProxy get copyWith => _$ImportBotRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportBotRequest _$ImportBotRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ImportBotRequest',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['org_id', 'template', 'credential_id', 'model'],
        );
        final val = ImportBotRequest(
          orgId: $checkedConvert('org_id', (v) => v as String),
          template: $checkedConvert(
            'template',
            (v) => BotTemplateFile.fromJson(v as Map<String, dynamic>),
          ),
          credentialId: $checkedConvert('credential_id', (v) => v as String),
          model: $checkedConvert('model', (v) => v as String),
          includeMemories: $checkedConvert(
            'include_memories',
            (v) => v as bool? ?? true,
          ),
          includeRoutines: $checkedConvert(
            'include_routines',
            (v) => v as bool? ?? true,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'orgId': 'org_id',
        'credentialId': 'credential_id',
        'includeMemories': 'include_memories',
        'includeRoutines': 'include_routines',
      },
    );

Map<String, dynamic> _$ImportBotRequestToJson(ImportBotRequest instance) =>
    <String, dynamic>{
      'org_id': instance.orgId,
      'template': instance.template.toJson(),
      'credential_id': instance.credentialId,
      'model': instance.model,
      'include_memories': ?instance.includeMemories,
      'include_routines': ?instance.includeRoutines,
    };
