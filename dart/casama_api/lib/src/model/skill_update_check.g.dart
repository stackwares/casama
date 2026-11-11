// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_update_check.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SkillUpdateCheckCWProxy {
  SkillUpdateCheck currentCommit(String currentCommit);

  SkillUpdateCheck latestCommit(String latestCommit);

  SkillUpdateCheck hasUpdate(bool hasUpdate);

  SkillUpdateCheck diff(List<String> diff);

  SkillUpdateCheck filesAdded(List<String> filesAdded);

  SkillUpdateCheck filesRemoved(List<String> filesRemoved);

  SkillUpdateCheck filesChanged(List<String> filesChanged);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SkillUpdateCheck(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SkillUpdateCheck(...).copyWith(id: 12, name: "My name")
  /// ```
  SkillUpdateCheck call({
    String currentCommit,
    String latestCommit,
    bool hasUpdate,
    List<String> diff,
    List<String> filesAdded,
    List<String> filesRemoved,
    List<String> filesChanged,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSkillUpdateCheck.copyWith(...)` or call `instanceOfSkillUpdateCheck.copyWith.fieldName(value)` for a single field.
class _$SkillUpdateCheckCWProxyImpl implements _$SkillUpdateCheckCWProxy {
  const _$SkillUpdateCheckCWProxyImpl(this._value);

  final SkillUpdateCheck _value;

  @override
  SkillUpdateCheck currentCommit(String currentCommit) =>
      call(currentCommit: currentCommit);

  @override
  SkillUpdateCheck latestCommit(String latestCommit) =>
      call(latestCommit: latestCommit);

  @override
  SkillUpdateCheck hasUpdate(bool hasUpdate) => call(hasUpdate: hasUpdate);

  @override
  SkillUpdateCheck diff(List<String> diff) => call(diff: diff);

  @override
  SkillUpdateCheck filesAdded(List<String> filesAdded) =>
      call(filesAdded: filesAdded);

  @override
  SkillUpdateCheck filesRemoved(List<String> filesRemoved) =>
      call(filesRemoved: filesRemoved);

  @override
  SkillUpdateCheck filesChanged(List<String> filesChanged) =>
      call(filesChanged: filesChanged);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SkillUpdateCheck(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SkillUpdateCheck(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SkillUpdateCheck call({
    Object? currentCommit = const $CopyWithPlaceholder(),
    Object? latestCommit = const $CopyWithPlaceholder(),
    Object? hasUpdate = const $CopyWithPlaceholder(),
    Object? diff = const $CopyWithPlaceholder(),
    Object? filesAdded = const $CopyWithPlaceholder(),
    Object? filesRemoved = const $CopyWithPlaceholder(),
    Object? filesChanged = const $CopyWithPlaceholder(),
  }) {
    return SkillUpdateCheck(
      currentCommit:
          currentCommit == const $CopyWithPlaceholder() || currentCommit == null
          ? _value.currentCommit
          // ignore: cast_nullable_to_non_nullable
          : currentCommit as String,
      latestCommit:
          latestCommit == const $CopyWithPlaceholder() || latestCommit == null
          ? _value.latestCommit
          // ignore: cast_nullable_to_non_nullable
          : latestCommit as String,
      hasUpdate: hasUpdate == const $CopyWithPlaceholder() || hasUpdate == null
          ? _value.hasUpdate
          // ignore: cast_nullable_to_non_nullable
          : hasUpdate as bool,
      diff: diff == const $CopyWithPlaceholder() || diff == null
          ? _value.diff
          // ignore: cast_nullable_to_non_nullable
          : diff as List<String>,
      filesAdded:
          filesAdded == const $CopyWithPlaceholder() || filesAdded == null
          ? _value.filesAdded
          // ignore: cast_nullable_to_non_nullable
          : filesAdded as List<String>,
      filesRemoved:
          filesRemoved == const $CopyWithPlaceholder() || filesRemoved == null
          ? _value.filesRemoved
          // ignore: cast_nullable_to_non_nullable
          : filesRemoved as List<String>,
      filesChanged:
          filesChanged == const $CopyWithPlaceholder() || filesChanged == null
          ? _value.filesChanged
          // ignore: cast_nullable_to_non_nullable
          : filesChanged as List<String>,
    );
  }
}

extension $SkillUpdateCheckCopyWith on SkillUpdateCheck {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSkillUpdateCheck.copyWith(...)` or `instanceOfSkillUpdateCheck.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SkillUpdateCheckCWProxy get copyWith => _$SkillUpdateCheckCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkillUpdateCheck _$SkillUpdateCheckFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SkillUpdateCheck',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'current_commit',
            'latest_commit',
            'has_update',
            'diff',
            'files_added',
            'files_removed',
            'files_changed',
          ],
        );
        final val = SkillUpdateCheck(
          currentCommit: $checkedConvert('current_commit', (v) => v as String),
          latestCommit: $checkedConvert('latest_commit', (v) => v as String),
          hasUpdate: $checkedConvert('has_update', (v) => v as bool),
          diff: $checkedConvert(
            'diff',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          filesAdded: $checkedConvert(
            'files_added',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          filesRemoved: $checkedConvert(
            'files_removed',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          filesChanged: $checkedConvert(
            'files_changed',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'currentCommit': 'current_commit',
        'latestCommit': 'latest_commit',
        'hasUpdate': 'has_update',
        'filesAdded': 'files_added',
        'filesRemoved': 'files_removed',
        'filesChanged': 'files_changed',
      },
    );

Map<String, dynamic> _$SkillUpdateCheckToJson(SkillUpdateCheck instance) =>
    <String, dynamic>{
      'current_commit': instance.currentCommit,
      'latest_commit': instance.latestCommit,
      'has_update': instance.hasUpdate,
      'diff': instance.diff,
      'files_added': instance.filesAdded,
      'files_removed': instance.filesRemoved,
      'files_changed': instance.filesChanged,
    };
