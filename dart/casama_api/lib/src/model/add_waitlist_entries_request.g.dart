// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_waitlist_entries_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AddWaitlistEntriesRequestCWProxy {
  AddWaitlistEntriesRequest emails(List<String> emails);

  AddWaitlistEntriesRequest notify(bool? notify);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AddWaitlistEntriesRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AddWaitlistEntriesRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  AddWaitlistEntriesRequest call({List<String> emails, bool? notify});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAddWaitlistEntriesRequest.copyWith(...)` or call `instanceOfAddWaitlistEntriesRequest.copyWith.fieldName(value)` for a single field.
class _$AddWaitlistEntriesRequestCWProxyImpl
    implements _$AddWaitlistEntriesRequestCWProxy {
  const _$AddWaitlistEntriesRequestCWProxyImpl(this._value);

  final AddWaitlistEntriesRequest _value;

  @override
  AddWaitlistEntriesRequest emails(List<String> emails) => call(emails: emails);

  @override
  AddWaitlistEntriesRequest notify(bool? notify) => call(notify: notify);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AddWaitlistEntriesRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AddWaitlistEntriesRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AddWaitlistEntriesRequest call({
    Object? emails = const $CopyWithPlaceholder(),
    Object? notify = const $CopyWithPlaceholder(),
  }) {
    return AddWaitlistEntriesRequest(
      emails: emails == const $CopyWithPlaceholder() || emails == null
          ? _value.emails
          // ignore: cast_nullable_to_non_nullable
          : emails as List<String>,
      notify: notify == const $CopyWithPlaceholder()
          ? _value.notify
          // ignore: cast_nullable_to_non_nullable
          : notify as bool?,
    );
  }
}

extension $AddWaitlistEntriesRequestCopyWith on AddWaitlistEntriesRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAddWaitlistEntriesRequest.copyWith(...)` or `instanceOfAddWaitlistEntriesRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AddWaitlistEntriesRequestCWProxy get copyWith =>
      _$AddWaitlistEntriesRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddWaitlistEntriesRequest _$AddWaitlistEntriesRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AddWaitlistEntriesRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['emails']);
  final val = AddWaitlistEntriesRequest(
    emails: $checkedConvert(
      'emails',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    notify: $checkedConvert('notify', (v) => v as bool?),
  );
  return val;
});

Map<String, dynamic> _$AddWaitlistEntriesRequestToJson(
  AddWaitlistEntriesRequest instance,
) => <String, dynamic>{'emails': instance.emails, 'notify': ?instance.notify};
