// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_model_access.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminModelAccessCWProxy {
  AdminModelAccess ownProviders(bool ownProviders);

  AdminModelAccess casamaModels(AdminModelAccessCasamaModels casamaModels);

  AdminModelAccess note(String? note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminModelAccess(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminModelAccess(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminModelAccess call({
    bool ownProviders,
    AdminModelAccessCasamaModels casamaModels,
    String? note,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminModelAccess.copyWith(...)` or call `instanceOfAdminModelAccess.copyWith.fieldName(value)` for a single field.
class _$AdminModelAccessCWProxyImpl implements _$AdminModelAccessCWProxy {
  const _$AdminModelAccessCWProxyImpl(this._value);

  final AdminModelAccess _value;

  @override
  AdminModelAccess ownProviders(bool ownProviders) =>
      call(ownProviders: ownProviders);

  @override
  AdminModelAccess casamaModels(AdminModelAccessCasamaModels casamaModels) =>
      call(casamaModels: casamaModels);

  @override
  AdminModelAccess note(String? note) => call(note: note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminModelAccess(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminModelAccess(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminModelAccess call({
    Object? ownProviders = const $CopyWithPlaceholder(),
    Object? casamaModels = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return AdminModelAccess(
      ownProviders:
          ownProviders == const $CopyWithPlaceholder() || ownProviders == null
          ? _value.ownProviders
          // ignore: cast_nullable_to_non_nullable
          : ownProviders as bool,
      casamaModels:
          casamaModels == const $CopyWithPlaceholder() || casamaModels == null
          ? _value.casamaModels
          // ignore: cast_nullable_to_non_nullable
          : casamaModels as AdminModelAccessCasamaModels,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $AdminModelAccessCopyWith on AdminModelAccess {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminModelAccess.copyWith(...)` or `instanceOfAdminModelAccess.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminModelAccessCWProxy get copyWith => _$AdminModelAccessCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminModelAccess _$AdminModelAccessFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminModelAccess',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['own_providers', 'casama_models', 'note'],
        );
        final val = AdminModelAccess(
          ownProviders: $checkedConvert('own_providers', (v) => v as bool),
          casamaModels: $checkedConvert(
            'casama_models',
            (v) => AdminModelAccessCasamaModels.fromJson(
              v as Map<String, dynamic>,
            ),
          ),
          note: $checkedConvert('note', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'ownProviders': 'own_providers',
        'casamaModels': 'casama_models',
      },
    );

Map<String, dynamic> _$AdminModelAccessToJson(AdminModelAccess instance) =>
    <String, dynamic>{
      'own_providers': instance.ownProviders,
      'casama_models': instance.casamaModels.toJson(),
      'note': instance.note,
    };
