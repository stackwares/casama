// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_domains.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$JoinDomainsCWProxy {
  JoinDomains items(List<String> items);

  JoinDomains myDomain(String? myDomain);

  JoinDomains canUse(bool canUse);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `JoinDomains(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// JoinDomains(...).copyWith(id: 12, name: "My name")
  /// ```
  JoinDomains call({List<String> items, String? myDomain, bool canUse});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfJoinDomains.copyWith(...)` or call `instanceOfJoinDomains.copyWith.fieldName(value)` for a single field.
class _$JoinDomainsCWProxyImpl implements _$JoinDomainsCWProxy {
  const _$JoinDomainsCWProxyImpl(this._value);

  final JoinDomains _value;

  @override
  JoinDomains items(List<String> items) => call(items: items);

  @override
  JoinDomains myDomain(String? myDomain) => call(myDomain: myDomain);

  @override
  JoinDomains canUse(bool canUse) => call(canUse: canUse);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `JoinDomains(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// JoinDomains(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  JoinDomains call({
    Object? items = const $CopyWithPlaceholder(),
    Object? myDomain = const $CopyWithPlaceholder(),
    Object? canUse = const $CopyWithPlaceholder(),
  }) {
    return JoinDomains(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<String>,
      myDomain: myDomain == const $CopyWithPlaceholder()
          ? _value.myDomain
          // ignore: cast_nullable_to_non_nullable
          : myDomain as String?,
      canUse: canUse == const $CopyWithPlaceholder() || canUse == null
          ? _value.canUse
          // ignore: cast_nullable_to_non_nullable
          : canUse as bool,
    );
  }
}

extension $JoinDomainsCopyWith on JoinDomains {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfJoinDomains.copyWith(...)` or `instanceOfJoinDomains.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$JoinDomainsCWProxy get copyWith => _$JoinDomainsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JoinDomains _$JoinDomainsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('JoinDomains', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'my_domain', 'can_use']);
      final val = JoinDomains(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        myDomain: $checkedConvert('my_domain', (v) => v as String?),
        canUse: $checkedConvert('can_use', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'myDomain': 'my_domain', 'canUse': 'can_use'});

Map<String, dynamic> _$JoinDomainsToJson(JoinDomains instance) =>
    <String, dynamic>{
      'items': instance.items,
      'my_domain': instance.myDomain,
      'can_use': instance.canUse,
    };
