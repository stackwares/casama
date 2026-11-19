// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waitlist_entry.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WaitlistEntryCWProxy {
  WaitlistEntry id(String id);

  WaitlistEntry email(String email);

  WaitlistEntry status(WaitlistEntryStatusEnum status);

  WaitlistEntry source_(String? source_);

  WaitlistEntry ref(String? ref);

  WaitlistEntry selfHosting(bool selfHosting);

  WaitlistEntry note(String? note);

  WaitlistEntry priority(int priority);

  WaitlistEntry inviteCode(String? inviteCode);

  WaitlistEntry admittedVia(String? admittedVia);

  WaitlistEntry admittedAt(DateTime? admittedAt);

  WaitlistEntry joinedAt(DateTime? joinedAt);

  WaitlistEntry createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WaitlistEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WaitlistEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  WaitlistEntry call({
    String id,
    String email,
    WaitlistEntryStatusEnum status,
    String? source_,
    String? ref,
    bool selfHosting,
    String? note,
    int priority,
    String? inviteCode,
    String? admittedVia,
    DateTime? admittedAt,
    DateTime? joinedAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWaitlistEntry.copyWith(...)` or call `instanceOfWaitlistEntry.copyWith.fieldName(value)` for a single field.
class _$WaitlistEntryCWProxyImpl implements _$WaitlistEntryCWProxy {
  const _$WaitlistEntryCWProxyImpl(this._value);

  final WaitlistEntry _value;

  @override
  WaitlistEntry id(String id) => call(id: id);

  @override
  WaitlistEntry email(String email) => call(email: email);

  @override
  WaitlistEntry status(WaitlistEntryStatusEnum status) => call(status: status);

  @override
  WaitlistEntry source_(String? source_) => call(source_: source_);

  @override
  WaitlistEntry ref(String? ref) => call(ref: ref);

  @override
  WaitlistEntry selfHosting(bool selfHosting) => call(selfHosting: selfHosting);

  @override
  WaitlistEntry note(String? note) => call(note: note);

  @override
  WaitlistEntry priority(int priority) => call(priority: priority);

  @override
  WaitlistEntry inviteCode(String? inviteCode) => call(inviteCode: inviteCode);

  @override
  WaitlistEntry admittedVia(String? admittedVia) =>
      call(admittedVia: admittedVia);

  @override
  WaitlistEntry admittedAt(DateTime? admittedAt) =>
      call(admittedAt: admittedAt);

  @override
  WaitlistEntry joinedAt(DateTime? joinedAt) => call(joinedAt: joinedAt);

  @override
  WaitlistEntry createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WaitlistEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WaitlistEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WaitlistEntry call({
    Object? id = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? ref = const $CopyWithPlaceholder(),
    Object? selfHosting = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? priority = const $CopyWithPlaceholder(),
    Object? inviteCode = const $CopyWithPlaceholder(),
    Object? admittedVia = const $CopyWithPlaceholder(),
    Object? admittedAt = const $CopyWithPlaceholder(),
    Object? joinedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return WaitlistEntry(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      email: email == const $CopyWithPlaceholder() || email == null
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as WaitlistEntryStatusEnum,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as String?,
      ref: ref == const $CopyWithPlaceholder()
          ? _value.ref
          // ignore: cast_nullable_to_non_nullable
          : ref as String?,
      selfHosting:
          selfHosting == const $CopyWithPlaceholder() || selfHosting == null
          ? _value.selfHosting
          // ignore: cast_nullable_to_non_nullable
          : selfHosting as bool,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      priority: priority == const $CopyWithPlaceholder() || priority == null
          ? _value.priority
          // ignore: cast_nullable_to_non_nullable
          : priority as int,
      inviteCode: inviteCode == const $CopyWithPlaceholder()
          ? _value.inviteCode
          // ignore: cast_nullable_to_non_nullable
          : inviteCode as String?,
      admittedVia: admittedVia == const $CopyWithPlaceholder()
          ? _value.admittedVia
          // ignore: cast_nullable_to_non_nullable
          : admittedVia as String?,
      admittedAt: admittedAt == const $CopyWithPlaceholder()
          ? _value.admittedAt
          // ignore: cast_nullable_to_non_nullable
          : admittedAt as DateTime?,
      joinedAt: joinedAt == const $CopyWithPlaceholder()
          ? _value.joinedAt
          // ignore: cast_nullable_to_non_nullable
          : joinedAt as DateTime?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $WaitlistEntryCopyWith on WaitlistEntry {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWaitlistEntry.copyWith(...)` or `instanceOfWaitlistEntry.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WaitlistEntryCWProxy get copyWith => _$WaitlistEntryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WaitlistEntry _$WaitlistEntryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'WaitlistEntry',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'email',
            'status',
            'source',
            'ref',
            'self_hosting',
            'note',
            'priority',
            'invite_code',
            'admitted_via',
            'admitted_at',
            'joined_at',
            'created_at',
          ],
        );
        final val = WaitlistEntry(
          id: $checkedConvert('id', (v) => v as String),
          email: $checkedConvert('email', (v) => v as String),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$WaitlistEntryStatusEnumEnumMap, v),
          ),
          source_: $checkedConvert('source', (v) => v as String?),
          ref: $checkedConvert('ref', (v) => v as String?),
          selfHosting: $checkedConvert('self_hosting', (v) => v as bool),
          note: $checkedConvert('note', (v) => v as String?),
          priority: $checkedConvert('priority', (v) => (v as num).toInt()),
          inviteCode: $checkedConvert('invite_code', (v) => v as String?),
          admittedVia: $checkedConvert('admitted_via', (v) => v as String?),
          admittedAt: $checkedConvert(
            'admitted_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          joinedAt: $checkedConvert(
            'joined_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'source_': 'source',
        'selfHosting': 'self_hosting',
        'inviteCode': 'invite_code',
        'admittedVia': 'admitted_via',
        'admittedAt': 'admitted_at',
        'joinedAt': 'joined_at',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$WaitlistEntryToJson(WaitlistEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'status': _$WaitlistEntryStatusEnumEnumMap[instance.status]!,
      'source': instance.source_,
      'ref': instance.ref,
      'self_hosting': instance.selfHosting,
      'note': instance.note,
      'priority': instance.priority,
      'invite_code': instance.inviteCode,
      'admitted_via': instance.admittedVia,
      'admitted_at': instance.admittedAt?.toIso8601String(),
      'joined_at': instance.joinedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$WaitlistEntryStatusEnumEnumMap = {
  WaitlistEntryStatusEnum.waiting: 'waiting',
  WaitlistEntryStatusEnum.queued: 'queued',
  WaitlistEntryStatusEnum.admitted: 'admitted',
  WaitlistEntryStatusEnum.joined: 'joined',
};
