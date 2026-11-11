// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teach_step.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TeachStepCWProxy {
  TeachStep seq(int seq);

  TeachStep kind(TeachStepKindEnum kind);

  TeachStep x(int? x);

  TeachStep y(int? y);

  TeachStep button(int? button);

  TeachStep text(String? text);

  TeachStep key(String? key);

  TeachStep dx(int? dx);

  TeachStep dy(int? dy);

  TeachStep secretName(String? secretName);

  TeachStep password(bool password);

  TeachStep url(String? url);

  TeachStep hasScreenshot(bool hasScreenshot);

  TeachStep createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TeachStep(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TeachStep(...).copyWith(id: 12, name: "My name")
  /// ```
  TeachStep call({
    int seq,
    TeachStepKindEnum kind,
    int? x,
    int? y,
    int? button,
    String? text,
    String? key,
    int? dx,
    int? dy,
    String? secretName,
    bool password,
    String? url,
    bool hasScreenshot,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTeachStep.copyWith(...)` or call `instanceOfTeachStep.copyWith.fieldName(value)` for a single field.
class _$TeachStepCWProxyImpl implements _$TeachStepCWProxy {
  const _$TeachStepCWProxyImpl(this._value);

  final TeachStep _value;

  @override
  TeachStep seq(int seq) => call(seq: seq);

  @override
  TeachStep kind(TeachStepKindEnum kind) => call(kind: kind);

  @override
  TeachStep x(int? x) => call(x: x);

  @override
  TeachStep y(int? y) => call(y: y);

  @override
  TeachStep button(int? button) => call(button: button);

  @override
  TeachStep text(String? text) => call(text: text);

  @override
  TeachStep key(String? key) => call(key: key);

  @override
  TeachStep dx(int? dx) => call(dx: dx);

  @override
  TeachStep dy(int? dy) => call(dy: dy);

  @override
  TeachStep secretName(String? secretName) => call(secretName: secretName);

  @override
  TeachStep password(bool password) => call(password: password);

  @override
  TeachStep url(String? url) => call(url: url);

  @override
  TeachStep hasScreenshot(bool hasScreenshot) =>
      call(hasScreenshot: hasScreenshot);

  @override
  TeachStep createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TeachStep(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TeachStep(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TeachStep call({
    Object? seq = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? x = const $CopyWithPlaceholder(),
    Object? y = const $CopyWithPlaceholder(),
    Object? button = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
    Object? key = const $CopyWithPlaceholder(),
    Object? dx = const $CopyWithPlaceholder(),
    Object? dy = const $CopyWithPlaceholder(),
    Object? secretName = const $CopyWithPlaceholder(),
    Object? password = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? hasScreenshot = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return TeachStep(
      seq: seq == const $CopyWithPlaceholder() || seq == null
          ? _value.seq
          // ignore: cast_nullable_to_non_nullable
          : seq as int,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as TeachStepKindEnum,
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
      secretName: secretName == const $CopyWithPlaceholder()
          ? _value.secretName
          // ignore: cast_nullable_to_non_nullable
          : secretName as String?,
      password: password == const $CopyWithPlaceholder() || password == null
          ? _value.password
          // ignore: cast_nullable_to_non_nullable
          : password as bool,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
      hasScreenshot:
          hasScreenshot == const $CopyWithPlaceholder() || hasScreenshot == null
          ? _value.hasScreenshot
          // ignore: cast_nullable_to_non_nullable
          : hasScreenshot as bool,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $TeachStepCopyWith on TeachStep {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTeachStep.copyWith(...)` or `instanceOfTeachStep.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TeachStepCWProxy get copyWith => _$TeachStepCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeachStep _$TeachStepFromJson(Map<String, dynamic> json) => $checkedCreate(
  'TeachStep',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'seq',
        'kind',
        'x',
        'y',
        'button',
        'text',
        'key',
        'dx',
        'dy',
        'secret_name',
        'password',
        'url',
        'has_screenshot',
        'created_at',
      ],
    );
    final val = TeachStep(
      seq: $checkedConvert('seq', (v) => (v as num).toInt()),
      kind: $checkedConvert(
        'kind',
        (v) => $enumDecode(_$TeachStepKindEnumEnumMap, v),
      ),
      x: $checkedConvert('x', (v) => (v as num?)?.toInt()),
      y: $checkedConvert('y', (v) => (v as num?)?.toInt()),
      button: $checkedConvert('button', (v) => (v as num?)?.toInt()),
      text: $checkedConvert('text', (v) => v as String?),
      key: $checkedConvert('key', (v) => v as String?),
      dx: $checkedConvert('dx', (v) => (v as num?)?.toInt()),
      dy: $checkedConvert('dy', (v) => (v as num?)?.toInt()),
      secretName: $checkedConvert('secret_name', (v) => v as String?),
      password: $checkedConvert('password', (v) => v as bool),
      url: $checkedConvert('url', (v) => v as String?),
      hasScreenshot: $checkedConvert('has_screenshot', (v) => v as bool),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'secretName': 'secret_name',
    'hasScreenshot': 'has_screenshot',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$TeachStepToJson(TeachStep instance) => <String, dynamic>{
  'seq': instance.seq,
  'kind': _$TeachStepKindEnumEnumMap[instance.kind]!,
  'x': instance.x,
  'y': instance.y,
  'button': instance.button,
  'text': instance.text,
  'key': instance.key,
  'dx': instance.dx,
  'dy': instance.dy,
  'secret_name': instance.secretName,
  'password': instance.password,
  'url': instance.url,
  'has_screenshot': instance.hasScreenshot,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$TeachStepKindEnumEnumMap = {
  TeachStepKindEnum.click: 'click',
  TeachStepKindEnum.type: 'type',
  TeachStepKindEnum.key: 'key',
  TeachStepKindEnum.scroll: 'scroll',
};
