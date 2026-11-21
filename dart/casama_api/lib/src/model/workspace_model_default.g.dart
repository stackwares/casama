// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_model_default.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WorkspaceModelDefaultCWProxy {
  WorkspaceModelDefault source_(WorkspaceModelDefaultSource_Enum source_);

  WorkspaceModelDefault credentialId(String? credentialId);

  WorkspaceModelDefault model(String? model);

  WorkspaceModelDefault cheapModel(String? cheapModel);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WorkspaceModelDefault(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WorkspaceModelDefault(...).copyWith(id: 12, name: "My name")
  /// ```
  WorkspaceModelDefault call({
    WorkspaceModelDefaultSource_Enum source_,
    String? credentialId,
    String? model,
    String? cheapModel,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWorkspaceModelDefault.copyWith(...)` or call `instanceOfWorkspaceModelDefault.copyWith.fieldName(value)` for a single field.
class _$WorkspaceModelDefaultCWProxyImpl
    implements _$WorkspaceModelDefaultCWProxy {
  const _$WorkspaceModelDefaultCWProxyImpl(this._value);

  final WorkspaceModelDefault _value;

  @override
  WorkspaceModelDefault source_(WorkspaceModelDefaultSource_Enum source_) =>
      call(source_: source_);

  @override
  WorkspaceModelDefault credentialId(String? credentialId) =>
      call(credentialId: credentialId);

  @override
  WorkspaceModelDefault model(String? model) => call(model: model);

  @override
  WorkspaceModelDefault cheapModel(String? cheapModel) =>
      call(cheapModel: cheapModel);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WorkspaceModelDefault(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WorkspaceModelDefault(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WorkspaceModelDefault call({
    Object? source_ = const $CopyWithPlaceholder(),
    Object? credentialId = const $CopyWithPlaceholder(),
    Object? model = const $CopyWithPlaceholder(),
    Object? cheapModel = const $CopyWithPlaceholder(),
  }) {
    return WorkspaceModelDefault(
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as WorkspaceModelDefaultSource_Enum,
      credentialId: credentialId == const $CopyWithPlaceholder()
          ? _value.credentialId
          // ignore: cast_nullable_to_non_nullable
          : credentialId as String?,
      model: model == const $CopyWithPlaceholder()
          ? _value.model
          // ignore: cast_nullable_to_non_nullable
          : model as String?,
      cheapModel: cheapModel == const $CopyWithPlaceholder()
          ? _value.cheapModel
          // ignore: cast_nullable_to_non_nullable
          : cheapModel as String?,
    );
  }
}

extension $WorkspaceModelDefaultCopyWith on WorkspaceModelDefault {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWorkspaceModelDefault.copyWith(...)` or `instanceOfWorkspaceModelDefault.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WorkspaceModelDefaultCWProxy get copyWith =>
      _$WorkspaceModelDefaultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkspaceModelDefault _$WorkspaceModelDefaultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'WorkspaceModelDefault',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['source']);
    final val = WorkspaceModelDefault(
      source_: $checkedConvert(
        'source',
        (v) => $enumDecode(_$WorkspaceModelDefaultSource_EnumEnumMap, v),
      ),
      credentialId: $checkedConvert('credential_id', (v) => v as String?),
      model: $checkedConvert('model', (v) => v as String?),
      cheapModel: $checkedConvert('cheap_model', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'source_': 'source',
    'credentialId': 'credential_id',
    'cheapModel': 'cheap_model',
  },
);

Map<String, dynamic> _$WorkspaceModelDefaultToJson(
  WorkspaceModelDefault instance,
) => <String, dynamic>{
  'source': _$WorkspaceModelDefaultSource_EnumEnumMap[instance.source_]!,
  'credential_id': ?instance.credentialId,
  'model': ?instance.model,
  'cheap_model': ?instance.cheapModel,
};

const _$WorkspaceModelDefaultSource_EnumEnumMap = {
  WorkspaceModelDefaultSource_Enum.casama: 'casama',
  WorkspaceModelDefaultSource_Enum.own: 'own',
};
