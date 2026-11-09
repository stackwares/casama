// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_checkpoint_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateCheckpointRequestCWProxy {
  CreateCheckpointRequest label(String label);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateCheckpointRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateCheckpointRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateCheckpointRequest call({String label});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCreateCheckpointRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCreateCheckpointRequest.copyWith.fieldName(...)`
class _$CreateCheckpointRequestCWProxyImpl
    implements _$CreateCheckpointRequestCWProxy {
  const _$CreateCheckpointRequestCWProxyImpl(this._value);

  final CreateCheckpointRequest _value;

  @override
  CreateCheckpointRequest label(String label) => this(label: label);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateCheckpointRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateCheckpointRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateCheckpointRequest call({Object? label = const $CopyWithPlaceholder()}) {
    return CreateCheckpointRequest(
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
    );
  }
}

extension $CreateCheckpointRequestCopyWith on CreateCheckpointRequest {
  /// Returns a callable class that can be used as follows: `instanceOfCreateCheckpointRequest.copyWith(...)` or like so:`instanceOfCreateCheckpointRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateCheckpointRequestCWProxy get copyWith =>
      _$CreateCheckpointRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCheckpointRequest _$CreateCheckpointRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateCheckpointRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['label']);
  final val = CreateCheckpointRequest(
    label: $checkedConvert('label', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$CreateCheckpointRequestToJson(
  CreateCheckpointRequest instance,
) => <String, dynamic>{'label': instance.label};
