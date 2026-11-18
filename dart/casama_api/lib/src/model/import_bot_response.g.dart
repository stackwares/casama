// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_bot_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ImportBotResponseCWProxy {
  ImportBotResponse botId(String botId);

  ImportBotResponse skills(int skills);

  ImportBotResponse routines(int routines);

  ImportBotResponse memories(int memories);

  ImportBotResponse connectionsToAdd(
    List<ImportBotResponseConnectionsToAddInner> connectionsToAdd,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ImportBotResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ImportBotResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  ImportBotResponse call({
    String botId,
    int skills,
    int routines,
    int memories,
    List<ImportBotResponseConnectionsToAddInner> connectionsToAdd,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfImportBotResponse.copyWith(...)` or call `instanceOfImportBotResponse.copyWith.fieldName(value)` for a single field.
class _$ImportBotResponseCWProxyImpl implements _$ImportBotResponseCWProxy {
  const _$ImportBotResponseCWProxyImpl(this._value);

  final ImportBotResponse _value;

  @override
  ImportBotResponse botId(String botId) => call(botId: botId);

  @override
  ImportBotResponse skills(int skills) => call(skills: skills);

  @override
  ImportBotResponse routines(int routines) => call(routines: routines);

  @override
  ImportBotResponse memories(int memories) => call(memories: memories);

  @override
  ImportBotResponse connectionsToAdd(
    List<ImportBotResponseConnectionsToAddInner> connectionsToAdd,
  ) => call(connectionsToAdd: connectionsToAdd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ImportBotResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ImportBotResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ImportBotResponse call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? skills = const $CopyWithPlaceholder(),
    Object? routines = const $CopyWithPlaceholder(),
    Object? memories = const $CopyWithPlaceholder(),
    Object? connectionsToAdd = const $CopyWithPlaceholder(),
  }) {
    return ImportBotResponse(
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      skills: skills == const $CopyWithPlaceholder() || skills == null
          ? _value.skills
          // ignore: cast_nullable_to_non_nullable
          : skills as int,
      routines: routines == const $CopyWithPlaceholder() || routines == null
          ? _value.routines
          // ignore: cast_nullable_to_non_nullable
          : routines as int,
      memories: memories == const $CopyWithPlaceholder() || memories == null
          ? _value.memories
          // ignore: cast_nullable_to_non_nullable
          : memories as int,
      connectionsToAdd:
          connectionsToAdd == const $CopyWithPlaceholder() ||
              connectionsToAdd == null
          ? _value.connectionsToAdd
          // ignore: cast_nullable_to_non_nullable
          : connectionsToAdd as List<ImportBotResponseConnectionsToAddInner>,
    );
  }
}

extension $ImportBotResponseCopyWith on ImportBotResponse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfImportBotResponse.copyWith(...)` or `instanceOfImportBotResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ImportBotResponseCWProxy get copyWith =>
      _$ImportBotResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportBotResponse _$ImportBotResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ImportBotResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'bot_id',
            'skills',
            'routines',
            'memories',
            'connections_to_add',
          ],
        );
        final val = ImportBotResponse(
          botId: $checkedConvert('bot_id', (v) => v as String),
          skills: $checkedConvert('skills', (v) => (v as num).toInt()),
          routines: $checkedConvert('routines', (v) => (v as num).toInt()),
          memories: $checkedConvert('memories', (v) => (v as num).toInt()),
          connectionsToAdd: $checkedConvert(
            'connections_to_add',
            (v) => (v as List<dynamic>)
                .map(
                  (e) => ImportBotResponseConnectionsToAddInner.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'botId': 'bot_id',
        'connectionsToAdd': 'connections_to_add',
      },
    );

Map<String, dynamic> _$ImportBotResponseToJson(ImportBotResponse instance) =>
    <String, dynamic>{
      'bot_id': instance.botId,
      'skills': instance.skills,
      'routines': instance.routines,
      'memories': instance.memories,
      'connections_to_add': instance.connectionsToAdd
          .map((e) => e.toJson())
          .toList(),
    };
