// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refresh_live_card.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RefreshLiveCardCWProxy {
  RefreshLiveCard view(String? view);

  RefreshLiveCard force(bool? force);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RefreshLiveCard(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RefreshLiveCard(...).copyWith(id: 12, name: "My name")
  /// ```
  RefreshLiveCard call({String? view, bool? force});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRefreshLiveCard.copyWith(...)` or call `instanceOfRefreshLiveCard.copyWith.fieldName(value)` for a single field.
class _$RefreshLiveCardCWProxyImpl implements _$RefreshLiveCardCWProxy {
  const _$RefreshLiveCardCWProxyImpl(this._value);

  final RefreshLiveCard _value;

  @override
  RefreshLiveCard view(String? view) => call(view: view);

  @override
  RefreshLiveCard force(bool? force) => call(force: force);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RefreshLiveCard(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RefreshLiveCard(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RefreshLiveCard call({
    Object? view = const $CopyWithPlaceholder(),
    Object? force = const $CopyWithPlaceholder(),
  }) {
    return RefreshLiveCard(
      view: view == const $CopyWithPlaceholder()
          ? _value.view
          // ignore: cast_nullable_to_non_nullable
          : view as String?,
      force: force == const $CopyWithPlaceholder()
          ? _value.force
          // ignore: cast_nullable_to_non_nullable
          : force as bool?,
    );
  }
}

extension $RefreshLiveCardCopyWith on RefreshLiveCard {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRefreshLiveCard.copyWith(...)` or `instanceOfRefreshLiveCard.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RefreshLiveCardCWProxy get copyWith => _$RefreshLiveCardCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefreshLiveCard _$RefreshLiveCardFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RefreshLiveCard', json, ($checkedConvert) {
      final val = RefreshLiveCard(
        view: $checkedConvert('view', (v) => v as String?),
        force: $checkedConvert('force', (v) => v as bool?),
      );
      return val;
    });

Map<String, dynamic> _$RefreshLiveCardToJson(RefreshLiveCard instance) =>
    <String, dynamic>{'view': ?instance.view, 'force': ?instance.force};
