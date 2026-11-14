// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_creation_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateCreationRequestCWProxy {
  UpdateCreationRequest title(String? title);

  UpdateCreationRequest label(String? label);

  UpdateCreationRequest pinned(bool? pinned);

  UpdateCreationRequest opened(bool? opened);

  UpdateCreationRequest visibility(
    UpdateCreationRequestVisibilityEnum? visibility,
  );

  UpdateCreationRequest expiresInDays(int? expiresInDays);

  UpdateCreationRequest projectId(String? projectId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateCreationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateCreationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateCreationRequest call({
    String? title,
    String? label,
    bool? pinned,
    bool? opened,
    UpdateCreationRequestVisibilityEnum? visibility,
    int? expiresInDays,
    String? projectId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateCreationRequest.copyWith(...)` or call `instanceOfUpdateCreationRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateCreationRequestCWProxyImpl
    implements _$UpdateCreationRequestCWProxy {
  const _$UpdateCreationRequestCWProxyImpl(this._value);

  final UpdateCreationRequest _value;

  @override
  UpdateCreationRequest title(String? title) => call(title: title);

  @override
  UpdateCreationRequest label(String? label) => call(label: label);

  @override
  UpdateCreationRequest pinned(bool? pinned) => call(pinned: pinned);

  @override
  UpdateCreationRequest opened(bool? opened) => call(opened: opened);

  @override
  UpdateCreationRequest visibility(
    UpdateCreationRequestVisibilityEnum? visibility,
  ) => call(visibility: visibility);

  @override
  UpdateCreationRequest expiresInDays(int? expiresInDays) =>
      call(expiresInDays: expiresInDays);

  @override
  UpdateCreationRequest projectId(String? projectId) =>
      call(projectId: projectId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateCreationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateCreationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateCreationRequest call({
    Object? title = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? pinned = const $CopyWithPlaceholder(),
    Object? opened = const $CopyWithPlaceholder(),
    Object? visibility = const $CopyWithPlaceholder(),
    Object? expiresInDays = const $CopyWithPlaceholder(),
    Object? projectId = const $CopyWithPlaceholder(),
  }) {
    return UpdateCreationRequest(
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String?,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String?,
      pinned: pinned == const $CopyWithPlaceholder()
          ? _value.pinned
          // ignore: cast_nullable_to_non_nullable
          : pinned as bool?,
      opened: opened == const $CopyWithPlaceholder()
          ? _value.opened
          // ignore: cast_nullable_to_non_nullable
          : opened as bool?,
      visibility: visibility == const $CopyWithPlaceholder()
          ? _value.visibility
          // ignore: cast_nullable_to_non_nullable
          : visibility as UpdateCreationRequestVisibilityEnum?,
      expiresInDays: expiresInDays == const $CopyWithPlaceholder()
          ? _value.expiresInDays
          // ignore: cast_nullable_to_non_nullable
          : expiresInDays as int?,
      projectId: projectId == const $CopyWithPlaceholder()
          ? _value.projectId
          // ignore: cast_nullable_to_non_nullable
          : projectId as String?,
    );
  }
}

extension $UpdateCreationRequestCopyWith on UpdateCreationRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateCreationRequest.copyWith(...)` or `instanceOfUpdateCreationRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateCreationRequestCWProxy get copyWith =>
      _$UpdateCreationRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateCreationRequest _$UpdateCreationRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'UpdateCreationRequest',
  json,
  ($checkedConvert) {
    final val = UpdateCreationRequest(
      title: $checkedConvert('title', (v) => v as String?),
      label: $checkedConvert('label', (v) => v as String?),
      pinned: $checkedConvert('pinned', (v) => v as bool?),
      opened: $checkedConvert('opened', (v) => v as bool?),
      visibility: $checkedConvert(
        'visibility',
        (v) => $enumDecodeNullable(
          _$UpdateCreationRequestVisibilityEnumEnumMap,
          v,
        ),
      ),
      expiresInDays: $checkedConvert(
        'expires_in_days',
        (v) => (v as num?)?.toInt(),
      ),
      projectId: $checkedConvert('project_id', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'expiresInDays': 'expires_in_days',
    'projectId': 'project_id',
  },
);

Map<String, dynamic> _$UpdateCreationRequestToJson(
  UpdateCreationRequest instance,
) => <String, dynamic>{
  'title': ?instance.title,
  'label': ?instance.label,
  'pinned': ?instance.pinned,
  'opened': ?instance.opened,
  'visibility':
      ?_$UpdateCreationRequestVisibilityEnumEnumMap[instance.visibility],
  'expires_in_days': ?instance.expiresInDays,
  'project_id': ?instance.projectId,
};

const _$UpdateCreationRequestVisibilityEnumEnumMap = {
  UpdateCreationRequestVisibilityEnum.private: 'private',
  UpdateCreationRequestVisibilityEnum.workspace: 'workspace',
  UpdateCreationRequestVisibilityEnum.public: 'public',
};
