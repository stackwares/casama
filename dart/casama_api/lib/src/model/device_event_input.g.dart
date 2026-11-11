// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_event_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceEventInputCWProxy {
  DeviceEventInput id(String id);

  DeviceEventInput type(DeviceEventInputTypeEnum type);

  DeviceEventInput at(DateTime at);

  DeviceEventInput place(String? place);

  DeviceEventInput app(String? app);

  DeviceEventInput title(String? title);

  DeviceEventInput text(String? text);

  DeviceEventInput folder(String? folder);

  DeviceEventInput name(String? name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceEventInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceEventInput(...).copyWith(id: 12, name: "My name")
  /// ```
  DeviceEventInput call({
    String id,
    DeviceEventInputTypeEnum type,
    DateTime at,
    String? place,
    String? app,
    String? title,
    String? text,
    String? folder,
    String? name,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeviceEventInput.copyWith(...)` or call `instanceOfDeviceEventInput.copyWith.fieldName(value)` for a single field.
class _$DeviceEventInputCWProxyImpl implements _$DeviceEventInputCWProxy {
  const _$DeviceEventInputCWProxyImpl(this._value);

  final DeviceEventInput _value;

  @override
  DeviceEventInput id(String id) => call(id: id);

  @override
  DeviceEventInput type(DeviceEventInputTypeEnum type) => call(type: type);

  @override
  DeviceEventInput at(DateTime at) => call(at: at);

  @override
  DeviceEventInput place(String? place) => call(place: place);

  @override
  DeviceEventInput app(String? app) => call(app: app);

  @override
  DeviceEventInput title(String? title) => call(title: title);

  @override
  DeviceEventInput text(String? text) => call(text: text);

  @override
  DeviceEventInput folder(String? folder) => call(folder: folder);

  @override
  DeviceEventInput name(String? name) => call(name: name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceEventInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceEventInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeviceEventInput call({
    Object? id = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
    Object? place = const $CopyWithPlaceholder(),
    Object? app = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
    Object? folder = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return DeviceEventInput(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as DeviceEventInputTypeEnum,
      at: at == const $CopyWithPlaceholder() || at == null
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime,
      place: place == const $CopyWithPlaceholder()
          ? _value.place
          // ignore: cast_nullable_to_non_nullable
          : place as String?,
      app: app == const $CopyWithPlaceholder()
          ? _value.app
          // ignore: cast_nullable_to_non_nullable
          : app as String?,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String?,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String?,
      folder: folder == const $CopyWithPlaceholder()
          ? _value.folder
          // ignore: cast_nullable_to_non_nullable
          : folder as String?,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
    );
  }
}

extension $DeviceEventInputCopyWith on DeviceEventInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeviceEventInput.copyWith(...)` or `instanceOfDeviceEventInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceEventInputCWProxy get copyWith => _$DeviceEventInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceEventInput _$DeviceEventInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeviceEventInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'type', 'at']);
      final val = DeviceEventInput(
        id: $checkedConvert('id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$DeviceEventInputTypeEnumEnumMap, v),
        ),
        at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
        place: $checkedConvert('place', (v) => v as String?),
        app: $checkedConvert('app', (v) => v as String?),
        title: $checkedConvert('title', (v) => v as String?),
        text: $checkedConvert('text', (v) => v as String?),
        folder: $checkedConvert('folder', (v) => v as String?),
        name: $checkedConvert('name', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$DeviceEventInputToJson(DeviceEventInput instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$DeviceEventInputTypeEnumEnumMap[instance.type]!,
      'at': instance.at.toIso8601String(),
      'place': ?instance.place,
      'app': ?instance.app,
      'title': ?instance.title,
      'text': ?instance.text,
      'folder': ?instance.folder,
      'name': ?instance.name,
    };

const _$DeviceEventInputTypeEnumEnumMap = {
  DeviceEventInputTypeEnum.wake: 'wake',
  DeviceEventInputTypeEnum.arrive: 'arrive',
  DeviceEventInputTypeEnum.leave: 'leave',
  DeviceEventInputTypeEnum.workoutEnded: 'workout_ended',
  DeviceEventInputTypeEnum.notification: 'notification',
  DeviceEventInputTypeEnum.focusOn: 'focus_on',
  DeviceEventInputTypeEnum.focusOff: 'focus_off',
  DeviceEventInputTypeEnum.fileAdded: 'file_added',
  DeviceEventInputTypeEnum.drivingOn: 'driving_on',
  DeviceEventInputTypeEnum.drivingOff: 'driving_off',
};
