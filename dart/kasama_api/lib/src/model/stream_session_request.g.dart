// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stream_session_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StreamSessionRequestCWProxy {
  StreamSessionRequest mode(StreamMode? mode);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StreamSessionRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StreamSessionRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  StreamSessionRequest call({StreamMode? mode});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStreamSessionRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStreamSessionRequest.copyWith.fieldName(...)`
class _$StreamSessionRequestCWProxyImpl
    implements _$StreamSessionRequestCWProxy {
  const _$StreamSessionRequestCWProxyImpl(this._value);

  final StreamSessionRequest _value;

  @override
  StreamSessionRequest mode(StreamMode? mode) => this(mode: mode);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StreamSessionRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StreamSessionRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  StreamSessionRequest call({Object? mode = const $CopyWithPlaceholder()}) {
    return StreamSessionRequest(
      mode: mode == const $CopyWithPlaceholder()
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as StreamMode?,
    );
  }
}

extension $StreamSessionRequestCopyWith on StreamSessionRequest {
  /// Returns a callable class that can be used as follows: `instanceOfStreamSessionRequest.copyWith(...)` or like so:`instanceOfStreamSessionRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StreamSessionRequestCWProxy get copyWith =>
      _$StreamSessionRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StreamSessionRequest _$StreamSessionRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('StreamSessionRequest', json, ($checkedConvert) {
  final val = StreamSessionRequest(
    mode: $checkedConvert(
      'mode',
      (v) => $enumDecodeNullable(_$StreamModeEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$StreamSessionRequestToJson(
  StreamSessionRequest instance,
) => <String, dynamic>{'mode': ?_$StreamModeEnumMap[instance.mode]};

const _$StreamModeEnumMap = {
  StreamMode.view: 'view',
  StreamMode.control: 'control',
};
