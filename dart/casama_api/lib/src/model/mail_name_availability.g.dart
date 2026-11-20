// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mail_name_availability.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MailNameAvailabilityCWProxy {
  MailNameAvailability name(String name);

  MailNameAvailability available(bool available);

  MailNameAvailability issue(String? issue);

  MailNameAvailability suggestions(List<String> suggestions);

  MailNameAvailability domain(String? domain);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MailNameAvailability(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MailNameAvailability(...).copyWith(id: 12, name: "My name")
  /// ```
  MailNameAvailability call({
    String name,
    bool available,
    String? issue,
    List<String> suggestions,
    String? domain,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMailNameAvailability.copyWith(...)` or call `instanceOfMailNameAvailability.copyWith.fieldName(value)` for a single field.
class _$MailNameAvailabilityCWProxyImpl
    implements _$MailNameAvailabilityCWProxy {
  const _$MailNameAvailabilityCWProxyImpl(this._value);

  final MailNameAvailability _value;

  @override
  MailNameAvailability name(String name) => call(name: name);

  @override
  MailNameAvailability available(bool available) => call(available: available);

  @override
  MailNameAvailability issue(String? issue) => call(issue: issue);

  @override
  MailNameAvailability suggestions(List<String> suggestions) =>
      call(suggestions: suggestions);

  @override
  MailNameAvailability domain(String? domain) => call(domain: domain);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MailNameAvailability(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MailNameAvailability(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MailNameAvailability call({
    Object? name = const $CopyWithPlaceholder(),
    Object? available = const $CopyWithPlaceholder(),
    Object? issue = const $CopyWithPlaceholder(),
    Object? suggestions = const $CopyWithPlaceholder(),
    Object? domain = const $CopyWithPlaceholder(),
  }) {
    return MailNameAvailability(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      available: available == const $CopyWithPlaceholder() || available == null
          ? _value.available
          // ignore: cast_nullable_to_non_nullable
          : available as bool,
      issue: issue == const $CopyWithPlaceholder()
          ? _value.issue
          // ignore: cast_nullable_to_non_nullable
          : issue as String?,
      suggestions:
          suggestions == const $CopyWithPlaceholder() || suggestions == null
          ? _value.suggestions
          // ignore: cast_nullable_to_non_nullable
          : suggestions as List<String>,
      domain: domain == const $CopyWithPlaceholder()
          ? _value.domain
          // ignore: cast_nullable_to_non_nullable
          : domain as String?,
    );
  }
}

extension $MailNameAvailabilityCopyWith on MailNameAvailability {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMailNameAvailability.copyWith(...)` or `instanceOfMailNameAvailability.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MailNameAvailabilityCWProxy get copyWith =>
      _$MailNameAvailabilityCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MailNameAvailability _$MailNameAvailabilityFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('MailNameAvailability', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['name', 'available', 'issue', 'suggestions'],
  );
  final val = MailNameAvailability(
    name: $checkedConvert('name', (v) => v as String),
    available: $checkedConvert('available', (v) => v as bool),
    issue: $checkedConvert('issue', (v) => v as String?),
    suggestions: $checkedConvert(
      'suggestions',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    domain: $checkedConvert('domain', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$MailNameAvailabilityToJson(
  MailNameAvailability instance,
) => <String, dynamic>{
  'name': instance.name,
  'available': instance.available,
  'issue': instance.issue,
  'suggestions': instance.suggestions,
  'domain': ?instance.domain,
};
