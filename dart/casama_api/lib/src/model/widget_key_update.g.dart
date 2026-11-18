// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widget_key_update.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WidgetKeyUpdateCWProxy {
  WidgetKeyUpdate private(bool? private);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WidgetKeyUpdate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WidgetKeyUpdate(...).copyWith(id: 12, name: "My name")
  /// ```
  WidgetKeyUpdate call({bool? private});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWidgetKeyUpdate.copyWith(...)` or call `instanceOfWidgetKeyUpdate.copyWith.fieldName(value)` for a single field.
class _$WidgetKeyUpdateCWProxyImpl implements _$WidgetKeyUpdateCWProxy {
  const _$WidgetKeyUpdateCWProxyImpl(this._value);

  final WidgetKeyUpdate _value;

  @override
  WidgetKeyUpdate private(bool? private) => call(private: private);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WidgetKeyUpdate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WidgetKeyUpdate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WidgetKeyUpdate call({Object? private = const $CopyWithPlaceholder()}) {
    return WidgetKeyUpdate(
      private: private == const $CopyWithPlaceholder()
          ? _value.private
          // ignore: cast_nullable_to_non_nullable
          : private as bool?,
    );
  }
}

extension $WidgetKeyUpdateCopyWith on WidgetKeyUpdate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWidgetKeyUpdate.copyWith(...)` or `instanceOfWidgetKeyUpdate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WidgetKeyUpdateCWProxy get copyWith => _$WidgetKeyUpdateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WidgetKeyUpdate _$WidgetKeyUpdateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WidgetKeyUpdate', json, ($checkedConvert) {
      final val = WidgetKeyUpdate(
        private: $checkedConvert('private', (v) => v as bool?),
      );
      return val;
    });

Map<String, dynamic> _$WidgetKeyUpdateToJson(WidgetKeyUpdate instance) =>
    <String, dynamic>{'private': ?instance.private};
