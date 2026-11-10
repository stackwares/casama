// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_teach_step_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AddTeachStepRequestCWProxy {
  AddTeachStepRequest kind(AddTeachStepRequestKindEnum kind);

  AddTeachStepRequest x(int? x);

  AddTeachStepRequest y(int? y);

  AddTeachStepRequest button(int? button);

  AddTeachStepRequest text(String? text);

  AddTeachStepRequest key(String? key);

  AddTeachStepRequest dx(int? dx);

  AddTeachStepRequest dy(int? dy);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AddTeachStepRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AddTeachStepRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  AddTeachStepRequest call({
    AddTeachStepRequestKindEnum kind,
    int? x,
    int? y,
    int? button,
    String? text,
    String? key,
    int? dx,
    int? dy,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAddTeachStepRequest.copyWith(...)` or call `instanceOfAddTeachStepRequest.copyWith.fieldName(value)` for a single field.
class _$AddTeachStepRequestCWProxyImpl implements _$AddTeachStepRequestCWProxy {
  const _$AddTeachStepRequestCWProxyImpl(this._value);

  final AddTeachStepRequest _value;

  @override
  AddTeachStepRequest kind(AddTeachStepRequestKindEnum kind) =>
      call(kind: kind);

  @override
  AddTeachStepRequest x(int? x) => call(x: x);

  @override
  AddTeachStepRequest y(int? y) => call(y: y);

  @override
  AddTeachStepRequest button(int? button) => call(button: button);

  @override
  AddTeachStepRequest text(String? text) => call(text: text);

  @override
  AddTeachStepRequest key(String? key) => call(key: key);

  @override
  AddTeachStepRequest dx(int? dx) => call(dx: dx);

  @override
  AddTeachStepRequest dy(int? dy) => call(dy: dy);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AddTeachStepRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AddTeachStepRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AddTeachStepRequest call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? x = const $CopyWithPlaceholder(),
    Object? y = const $CopyWithPlaceholder(),
    Object? button = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
    Object? key = const $CopyWithPlaceholder(),
    Object? dx = const $CopyWithPlaceholder(),
    Object? dy = const $CopyWithPlaceholder(),
  }) {
    return AddTeachStepRequest(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as AddTeachStepRequestKindEnum,
      x: x == const $CopyWithPlaceholder()
          ? _value.x
          // ignore: cast_nullable_to_non_nullable
          : x as int?,
      y: y == const $CopyWithPlaceholder()
          ? _value.y
          // ignore: cast_nullable_to_non_nullable
          : y as int?,
      button: button == const $CopyWithPlaceholder()
          ? _value.button
          // ignore: cast_nullable_to_non_nullable
          : button as int?,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String?,
      key: key == const $CopyWithPlaceholder()
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String?,
      dx: dx == const $CopyWithPlaceholder()
          ? _value.dx
          // ignore: cast_nullable_to_non_nullable
          : dx as int?,
      dy: dy == const $CopyWithPlaceholder()
          ? _value.dy
          // ignore: cast_nullable_to_non_nullable
          : dy as int?,
    );
  }
}

extension $AddTeachStepRequestCopyWith on AddTeachStepRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAddTeachStepRequest.copyWith(...)` or `instanceOfAddTeachStepRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AddTeachStepRequestCWProxy get copyWith =>
      _$AddTeachStepRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddTeachStepRequest _$AddTeachStepRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AddTeachStepRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['kind']);
      final val = AddTeachStepRequest(
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$AddTeachStepRequestKindEnumEnumMap, v),
        ),
        x: $checkedConvert('x', (v) => (v as num?)?.toInt()),
        y: $checkedConvert('y', (v) => (v as num?)?.toInt()),
        button: $checkedConvert('button', (v) => (v as num?)?.toInt()),
        text: $checkedConvert('text', (v) => v as String?),
        key: $checkedConvert('key', (v) => v as String?),
        dx: $checkedConvert('dx', (v) => (v as num?)?.toInt()),
        dy: $checkedConvert('dy', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$AddTeachStepRequestToJson(
  AddTeachStepRequest instance,
) => <String, dynamic>{
  'kind': _$AddTeachStepRequestKindEnumEnumMap[instance.kind]!,
  'x': ?instance.x,
  'y': ?instance.y,
  'button': ?instance.button,
  'text': ?instance.text,
  'key': ?instance.key,
  'dx': ?instance.dx,
  'dy': ?instance.dy,
};

const _$AddTeachStepRequestKindEnumEnumMap = {
  AddTeachStepRequestKindEnum.click: 'click',
  AddTeachStepRequestKindEnum.type: 'type',
  AddTeachStepRequestKindEnum.key: 'key',
  AddTeachStepRequestKindEnum.scroll: 'scroll',
};
