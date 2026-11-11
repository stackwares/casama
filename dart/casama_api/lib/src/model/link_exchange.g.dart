// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_exchange.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LinkExchangeCWProxy {
  LinkExchange id(String id);

  LinkExchange direction(LinkExchangeDirectionEnum direction);

  LinkExchange request(String request);

  LinkExchange response(String? response);

  LinkExchange status(LinkExchangeStatusEnum status);

  LinkExchange createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LinkExchange(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LinkExchange(...).copyWith(id: 12, name: "My name")
  /// ```
  LinkExchange call({
    String id,
    LinkExchangeDirectionEnum direction,
    String request,
    String? response,
    LinkExchangeStatusEnum status,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLinkExchange.copyWith(...)` or call `instanceOfLinkExchange.copyWith.fieldName(value)` for a single field.
class _$LinkExchangeCWProxyImpl implements _$LinkExchangeCWProxy {
  const _$LinkExchangeCWProxyImpl(this._value);

  final LinkExchange _value;

  @override
  LinkExchange id(String id) => call(id: id);

  @override
  LinkExchange direction(LinkExchangeDirectionEnum direction) =>
      call(direction: direction);

  @override
  LinkExchange request(String request) => call(request: request);

  @override
  LinkExchange response(String? response) => call(response: response);

  @override
  LinkExchange status(LinkExchangeStatusEnum status) => call(status: status);

  @override
  LinkExchange createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LinkExchange(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LinkExchange(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LinkExchange call({
    Object? id = const $CopyWithPlaceholder(),
    Object? direction = const $CopyWithPlaceholder(),
    Object? request = const $CopyWithPlaceholder(),
    Object? response = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return LinkExchange(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      direction: direction == const $CopyWithPlaceholder() || direction == null
          ? _value.direction
          // ignore: cast_nullable_to_non_nullable
          : direction as LinkExchangeDirectionEnum,
      request: request == const $CopyWithPlaceholder() || request == null
          ? _value.request
          // ignore: cast_nullable_to_non_nullable
          : request as String,
      response: response == const $CopyWithPlaceholder()
          ? _value.response
          // ignore: cast_nullable_to_non_nullable
          : response as String?,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as LinkExchangeStatusEnum,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $LinkExchangeCopyWith on LinkExchange {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLinkExchange.copyWith(...)` or `instanceOfLinkExchange.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LinkExchangeCWProxy get copyWith => _$LinkExchangeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LinkExchange _$LinkExchangeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LinkExchange', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'direction',
          'request',
          'response',
          'status',
          'created_at',
        ],
      );
      final val = LinkExchange(
        id: $checkedConvert('id', (v) => v as String),
        direction: $checkedConvert(
          'direction',
          (v) => $enumDecode(_$LinkExchangeDirectionEnumEnumMap, v),
        ),
        request: $checkedConvert('request', (v) => v as String),
        response: $checkedConvert('response', (v) => v as String?),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$LinkExchangeStatusEnumEnumMap, v),
        ),
        createdAt: $checkedConvert(
          'created_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'createdAt': 'created_at'});

Map<String, dynamic> _$LinkExchangeToJson(LinkExchange instance) =>
    <String, dynamic>{
      'id': instance.id,
      'direction': _$LinkExchangeDirectionEnumEnumMap[instance.direction]!,
      'request': instance.request,
      'response': instance.response,
      'status': _$LinkExchangeStatusEnumEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$LinkExchangeDirectionEnumEnumMap = {
  LinkExchangeDirectionEnum.out_: 'out',
  LinkExchangeDirectionEnum.in_: 'in',
};

const _$LinkExchangeStatusEnumEnumMap = {
  LinkExchangeStatusEnum.working: 'working',
  LinkExchangeStatusEnum.answered: 'answered',
  LinkExchangeStatusEnum.failed: 'failed',
};
