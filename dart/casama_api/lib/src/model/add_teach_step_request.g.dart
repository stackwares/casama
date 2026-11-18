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

  AddTeachStepRequest target(TeachTarget? target);

  AddTeachStepRequest url(String? url);

  AddTeachStepRequest password(bool? password);

  AddTeachStepRequest snapshot(String? snapshot);

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
    TeachTarget? target,
    String? url,
    bool? password,
    String? snapshot,
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

  @override
  AddTeachStepRequest target(TeachTarget? target) => call(target: target);

  @override
  AddTeachStepRequest url(String? url) => call(url: url);

  @override
  AddTeachStepRequest password(bool? password) => call(password: password);

  @override
  AddTeachStepRequest snapshot(String? snapshot) => call(snapshot: snapshot);

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
    Object? target = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? password = const $CopyWithPlaceholder(),
    Object? snapshot = const $CopyWithPlaceholder(),
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
      target: target == const $CopyWithPlaceholder()
          ? _value.target
          // ignore: cast_nullable_to_non_nullable
          : target as TeachTarget?,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
      password: password == const $CopyWithPlaceholder()
          ? _value.password
          // ignore: cast_nullable_to_non_nullable
          : password as bool?,
      snapshot: snapshot == const $CopyWithPlaceholder()
          ? _value.snapshot
          // ignore: cast_nullable_to_non_nullable
          : snapshot as String?,
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
        target: $checkedConvert(
          'target',
          (v) => v == null
              ? null
              : TeachTarget.fromJson(v as Map<String, dynamic>),
        ),
        url: $checkedConvert('url', (v) => v as String?),
        password: $checkedConvert('password', (v) => v as bool?),
        snapshot: $checkedConvert('snapshot', (v) => v as String?),
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
  'target': ?instance.target?.toJson(),
  'url': ?instance.url,
  'password': ?instance.password,
  'snapshot': ?instance.snapshot,
};

const _$AddTeachStepRequestKindEnumEnumMap = {
  AddTeachStepRequestKindEnum.click: 'click',
  AddTeachStepRequestKindEnum.type: 'type',
  AddTeachStepRequestKindEnum.key: 'key',
  AddTeachStepRequestKindEnum.scroll: 'scroll',
  AddTeachStepRequestKindEnum.open: 'open',
};
