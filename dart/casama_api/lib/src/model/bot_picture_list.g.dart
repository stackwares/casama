// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_picture_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotPictureListCWProxy {
  BotPictureList items(List<BotPicture> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotPictureList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotPictureList(...).copyWith(id: 12, name: "My name")
  /// ```
  BotPictureList call({List<BotPicture> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotPictureList.copyWith(...)` or call `instanceOfBotPictureList.copyWith.fieldName(value)` for a single field.
class _$BotPictureListCWProxyImpl implements _$BotPictureListCWProxy {
  const _$BotPictureListCWProxyImpl(this._value);

  final BotPictureList _value;

  @override
  BotPictureList items(List<BotPicture> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotPictureList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotPictureList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotPictureList call({Object? items = const $CopyWithPlaceholder()}) {
    return BotPictureList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<BotPicture>,
    );
  }
}

extension $BotPictureListCopyWith on BotPictureList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotPictureList.copyWith(...)` or `instanceOfBotPictureList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotPictureListCWProxy get copyWith => _$BotPictureListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotPictureList _$BotPictureListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BotPictureList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = BotPictureList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => BotPicture.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$BotPictureListToJson(BotPictureList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
