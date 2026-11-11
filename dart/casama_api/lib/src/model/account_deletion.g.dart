// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_deletion.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AccountDeletionCWProxy {
  AccountDeletion purgeAfter(DateTime purgeAfter);

  AccountDeletion workspacesDeleted(List<String> workspacesDeleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AccountDeletion(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AccountDeletion(...).copyWith(id: 12, name: "My name")
  /// ```
  AccountDeletion call({DateTime purgeAfter, List<String> workspacesDeleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAccountDeletion.copyWith(...)` or call `instanceOfAccountDeletion.copyWith.fieldName(value)` for a single field.
class _$AccountDeletionCWProxyImpl implements _$AccountDeletionCWProxy {
  const _$AccountDeletionCWProxyImpl(this._value);

  final AccountDeletion _value;

  @override
  AccountDeletion purgeAfter(DateTime purgeAfter) =>
      call(purgeAfter: purgeAfter);

  @override
  AccountDeletion workspacesDeleted(List<String> workspacesDeleted) =>
      call(workspacesDeleted: workspacesDeleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AccountDeletion(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AccountDeletion(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AccountDeletion call({
    Object? purgeAfter = const $CopyWithPlaceholder(),
    Object? workspacesDeleted = const $CopyWithPlaceholder(),
  }) {
    return AccountDeletion(
      purgeAfter:
          purgeAfter == const $CopyWithPlaceholder() || purgeAfter == null
          ? _value.purgeAfter
          // ignore: cast_nullable_to_non_nullable
          : purgeAfter as DateTime,
      workspacesDeleted:
          workspacesDeleted == const $CopyWithPlaceholder() ||
              workspacesDeleted == null
          ? _value.workspacesDeleted
          // ignore: cast_nullable_to_non_nullable
          : workspacesDeleted as List<String>,
    );
  }
}

extension $AccountDeletionCopyWith on AccountDeletion {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAccountDeletion.copyWith(...)` or `instanceOfAccountDeletion.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AccountDeletionCWProxy get copyWith => _$AccountDeletionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountDeletion _$AccountDeletionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AccountDeletion',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['purge_after', 'workspaces_deleted'],
        );
        final val = AccountDeletion(
          purgeAfter: $checkedConvert(
            'purge_after',
            (v) => DateTime.parse(v as String),
          ),
          workspacesDeleted: $checkedConvert(
            'workspaces_deleted',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'purgeAfter': 'purge_after',
        'workspacesDeleted': 'workspaces_deleted',
      },
    );

Map<String, dynamic> _$AccountDeletionToJson(AccountDeletion instance) =>
    <String, dynamic>{
      'purge_after': instance.purgeAfter.toIso8601String(),
      'workspaces_deleted': instance.workspacesDeleted,
    };
