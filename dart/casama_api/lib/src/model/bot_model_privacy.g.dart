// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_model_privacy.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotModelPrivacyCWProxy {
  BotModelPrivacy privateModel(bool privateModel);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotModelPrivacy(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotModelPrivacy(...).copyWith(id: 12, name: "My name")
  /// ```
  BotModelPrivacy call({bool privateModel});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotModelPrivacy.copyWith(...)` or call `instanceOfBotModelPrivacy.copyWith.fieldName(value)` for a single field.
class _$BotModelPrivacyCWProxyImpl implements _$BotModelPrivacyCWProxy {
  const _$BotModelPrivacyCWProxyImpl(this._value);

  final BotModelPrivacy _value;

  @override
  BotModelPrivacy privateModel(bool privateModel) =>
      call(privateModel: privateModel);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotModelPrivacy(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotModelPrivacy(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotModelPrivacy call({Object? privateModel = const $CopyWithPlaceholder()}) {
    return BotModelPrivacy(
      privateModel:
          privateModel == const $CopyWithPlaceholder() || privateModel == null
          ? _value.privateModel
          // ignore: cast_nullable_to_non_nullable
          : privateModel as bool,
    );
  }
}

extension $BotModelPrivacyCopyWith on BotModelPrivacy {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotModelPrivacy.copyWith(...)` or `instanceOfBotModelPrivacy.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotModelPrivacyCWProxy get copyWith => _$BotModelPrivacyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotModelPrivacy _$BotModelPrivacyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BotModelPrivacy', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['private_model']);
      final val = BotModelPrivacy(
        privateModel: $checkedConvert('private_model', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'privateModel': 'private_model'});

Map<String, dynamic> _$BotModelPrivacyToJson(BotModelPrivacy instance) =>
    <String, dynamic>{'private_model': instance.privateModel};
