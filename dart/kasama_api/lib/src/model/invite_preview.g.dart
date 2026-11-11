// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_preview.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InvitePreviewCWProxy {
  InvitePreview kind(InvitePreviewKindEnum kind);

  InvitePreview workspace(InvitePreviewWorkspace workspace);

  InvitePreview role(InvitePreviewRoleEnum role);

  InvitePreview inviterName(String? inviterName);

  InvitePreview requiresApproval(bool requiresApproval);

  InvitePreview emailHint(String? emailHint);

  InvitePreview alreadyMember(bool? alreadyMember);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InvitePreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InvitePreview(...).copyWith(id: 12, name: "My name")
  /// ```
  InvitePreview call({
    InvitePreviewKindEnum kind,
    InvitePreviewWorkspace workspace,
    InvitePreviewRoleEnum role,
    String? inviterName,
    bool requiresApproval,
    String? emailHint,
    bool? alreadyMember,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInvitePreview.copyWith(...)` or call `instanceOfInvitePreview.copyWith.fieldName(value)` for a single field.
class _$InvitePreviewCWProxyImpl implements _$InvitePreviewCWProxy {
  const _$InvitePreviewCWProxyImpl(this._value);

  final InvitePreview _value;

  @override
  InvitePreview kind(InvitePreviewKindEnum kind) => call(kind: kind);

  @override
  InvitePreview workspace(InvitePreviewWorkspace workspace) =>
      call(workspace: workspace);

  @override
  InvitePreview role(InvitePreviewRoleEnum role) => call(role: role);

  @override
  InvitePreview inviterName(String? inviterName) =>
      call(inviterName: inviterName);

  @override
  InvitePreview requiresApproval(bool requiresApproval) =>
      call(requiresApproval: requiresApproval);

  @override
  InvitePreview emailHint(String? emailHint) => call(emailHint: emailHint);

  @override
  InvitePreview alreadyMember(bool? alreadyMember) =>
      call(alreadyMember: alreadyMember);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InvitePreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InvitePreview(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InvitePreview call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? workspace = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? inviterName = const $CopyWithPlaceholder(),
    Object? requiresApproval = const $CopyWithPlaceholder(),
    Object? emailHint = const $CopyWithPlaceholder(),
    Object? alreadyMember = const $CopyWithPlaceholder(),
  }) {
    return InvitePreview(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as InvitePreviewKindEnum,
      workspace: workspace == const $CopyWithPlaceholder() || workspace == null
          ? _value.workspace
          // ignore: cast_nullable_to_non_nullable
          : workspace as InvitePreviewWorkspace,
      role: role == const $CopyWithPlaceholder() || role == null
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as InvitePreviewRoleEnum,
      inviterName: inviterName == const $CopyWithPlaceholder()
          ? _value.inviterName
          // ignore: cast_nullable_to_non_nullable
          : inviterName as String?,
      requiresApproval:
          requiresApproval == const $CopyWithPlaceholder() ||
              requiresApproval == null
          ? _value.requiresApproval
          // ignore: cast_nullable_to_non_nullable
          : requiresApproval as bool,
      emailHint: emailHint == const $CopyWithPlaceholder()
          ? _value.emailHint
          // ignore: cast_nullable_to_non_nullable
          : emailHint as String?,
      alreadyMember: alreadyMember == const $CopyWithPlaceholder()
          ? _value.alreadyMember
          // ignore: cast_nullable_to_non_nullable
          : alreadyMember as bool?,
    );
  }
}

extension $InvitePreviewCopyWith on InvitePreview {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInvitePreview.copyWith(...)` or `instanceOfInvitePreview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InvitePreviewCWProxy get copyWith => _$InvitePreviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvitePreview _$InvitePreviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'InvitePreview',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'kind',
            'workspace',
            'role',
            'inviter_name',
            'requires_approval',
            'email_hint',
            'already_member',
          ],
        );
        final val = InvitePreview(
          kind: $checkedConvert(
            'kind',
            (v) => $enumDecode(_$InvitePreviewKindEnumEnumMap, v),
          ),
          workspace: $checkedConvert(
            'workspace',
            (v) => InvitePreviewWorkspace.fromJson(v as Map<String, dynamic>),
          ),
          role: $checkedConvert(
            'role',
            (v) => $enumDecode(_$InvitePreviewRoleEnumEnumMap, v),
          ),
          inviterName: $checkedConvert('inviter_name', (v) => v as String?),
          requiresApproval: $checkedConvert(
            'requires_approval',
            (v) => v as bool,
          ),
          emailHint: $checkedConvert('email_hint', (v) => v as String?),
          alreadyMember: $checkedConvert('already_member', (v) => v as bool?),
        );
        return val;
      },
      fieldKeyMap: const {
        'inviterName': 'inviter_name',
        'requiresApproval': 'requires_approval',
        'emailHint': 'email_hint',
        'alreadyMember': 'already_member',
      },
    );

Map<String, dynamic> _$InvitePreviewToJson(InvitePreview instance) =>
    <String, dynamic>{
      'kind': _$InvitePreviewKindEnumEnumMap[instance.kind]!,
      'workspace': instance.workspace.toJson(),
      'role': _$InvitePreviewRoleEnumEnumMap[instance.role]!,
      'inviter_name': instance.inviterName,
      'requires_approval': instance.requiresApproval,
      'email_hint': instance.emailHint,
      'already_member': instance.alreadyMember,
    };

const _$InvitePreviewKindEnumEnumMap = {
  InvitePreviewKindEnum.link: 'link',
  InvitePreviewKindEnum.code: 'code',
  InvitePreviewKindEnum.email: 'email',
};

const _$InvitePreviewRoleEnumEnumMap = {
  InvitePreviewRoleEnum.owner: 'owner',
  InvitePreviewRoleEnum.admin: 'admin',
  InvitePreviewRoleEnum.member: 'member',
};
