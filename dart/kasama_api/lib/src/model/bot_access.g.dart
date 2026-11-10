// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_access.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotAccessCWProxy {
  BotAccess visibility(BotAccessVisibilityEnum visibility);

  BotAccess createdBy(String? createdBy);

  BotAccess entries(List<BotAccessEntry> entries);

  BotAccess canAdmin(bool canAdmin);

  BotAccess yourAccess(BotAccessYourAccessEnum yourAccess);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotAccess(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotAccess(...).copyWith(id: 12, name: "My name")
  /// ```
  BotAccess call({
    BotAccessVisibilityEnum visibility,
    String? createdBy,
    List<BotAccessEntry> entries,
    bool canAdmin,
    BotAccessYourAccessEnum yourAccess,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotAccess.copyWith(...)` or call `instanceOfBotAccess.copyWith.fieldName(value)` for a single field.
class _$BotAccessCWProxyImpl implements _$BotAccessCWProxy {
  const _$BotAccessCWProxyImpl(this._value);

  final BotAccess _value;

  @override
  BotAccess visibility(BotAccessVisibilityEnum visibility) =>
      call(visibility: visibility);

  @override
  BotAccess createdBy(String? createdBy) => call(createdBy: createdBy);

  @override
  BotAccess entries(List<BotAccessEntry> entries) => call(entries: entries);

  @override
  BotAccess canAdmin(bool canAdmin) => call(canAdmin: canAdmin);

  @override
  BotAccess yourAccess(BotAccessYourAccessEnum yourAccess) =>
      call(yourAccess: yourAccess);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotAccess(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotAccess(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotAccess call({
    Object? visibility = const $CopyWithPlaceholder(),
    Object? createdBy = const $CopyWithPlaceholder(),
    Object? entries = const $CopyWithPlaceholder(),
    Object? canAdmin = const $CopyWithPlaceholder(),
    Object? yourAccess = const $CopyWithPlaceholder(),
  }) {
    return BotAccess(
      visibility:
          visibility == const $CopyWithPlaceholder() || visibility == null
          ? _value.visibility
          // ignore: cast_nullable_to_non_nullable
          : visibility as BotAccessVisibilityEnum,
      createdBy: createdBy == const $CopyWithPlaceholder()
          ? _value.createdBy
          // ignore: cast_nullable_to_non_nullable
          : createdBy as String?,
      entries: entries == const $CopyWithPlaceholder() || entries == null
          ? _value.entries
          // ignore: cast_nullable_to_non_nullable
          : entries as List<BotAccessEntry>,
      canAdmin: canAdmin == const $CopyWithPlaceholder() || canAdmin == null
          ? _value.canAdmin
          // ignore: cast_nullable_to_non_nullable
          : canAdmin as bool,
      yourAccess:
          yourAccess == const $CopyWithPlaceholder() || yourAccess == null
          ? _value.yourAccess
          // ignore: cast_nullable_to_non_nullable
          : yourAccess as BotAccessYourAccessEnum,
    );
  }
}

extension $BotAccessCopyWith on BotAccess {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotAccess.copyWith(...)` or `instanceOfBotAccess.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotAccessCWProxy get copyWith => _$BotAccessCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotAccess _$BotAccessFromJson(Map<String, dynamic> json) => $checkedCreate(
  'BotAccess',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'visibility',
        'created_by',
        'entries',
        'can_admin',
        'your_access',
      ],
    );
    final val = BotAccess(
      visibility: $checkedConvert(
        'visibility',
        (v) => $enumDecode(_$BotAccessVisibilityEnumEnumMap, v),
      ),
      createdBy: $checkedConvert('created_by', (v) => v as String?),
      entries: $checkedConvert(
        'entries',
        (v) => (v as List<dynamic>)
            .map((e) => BotAccessEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      canAdmin: $checkedConvert('can_admin', (v) => v as bool),
      yourAccess: $checkedConvert(
        'your_access',
        (v) => $enumDecode(_$BotAccessYourAccessEnumEnumMap, v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'createdBy': 'created_by',
    'canAdmin': 'can_admin',
    'yourAccess': 'your_access',
  },
);

Map<String, dynamic> _$BotAccessToJson(BotAccess instance) => <String, dynamic>{
  'visibility': _$BotAccessVisibilityEnumEnumMap[instance.visibility]!,
  'created_by': instance.createdBy,
  'entries': instance.entries.map((e) => e.toJson()).toList(),
  'can_admin': instance.canAdmin,
  'your_access': _$BotAccessYourAccessEnumEnumMap[instance.yourAccess]!,
};

const _$BotAccessVisibilityEnumEnumMap = {
  BotAccessVisibilityEnum.private: 'private',
  BotAccessVisibilityEnum.team: 'team',
};

const _$BotAccessYourAccessEnumEnumMap = {
  BotAccessYourAccessEnum.chat: 'chat',
  BotAccessYourAccessEnum.edit: 'edit',
  BotAccessYourAccessEnum.admin: 'admin',
};
