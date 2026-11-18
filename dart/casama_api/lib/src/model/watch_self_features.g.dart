// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_self_features.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchSelfFeaturesCWProxy {
  WatchSelfFeatures dictation(bool dictation);

  WatchSelfFeatures speech(bool speech);

  WatchSelfFeatures outOfCredits(bool outOfCredits);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchSelfFeatures(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchSelfFeatures(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchSelfFeatures call({bool dictation, bool speech, bool outOfCredits});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchSelfFeatures.copyWith(...)` or call `instanceOfWatchSelfFeatures.copyWith.fieldName(value)` for a single field.
class _$WatchSelfFeaturesCWProxyImpl implements _$WatchSelfFeaturesCWProxy {
  const _$WatchSelfFeaturesCWProxyImpl(this._value);

  final WatchSelfFeatures _value;

  @override
  WatchSelfFeatures dictation(bool dictation) => call(dictation: dictation);

  @override
  WatchSelfFeatures speech(bool speech) => call(speech: speech);

  @override
  WatchSelfFeatures outOfCredits(bool outOfCredits) =>
      call(outOfCredits: outOfCredits);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchSelfFeatures(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchSelfFeatures(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchSelfFeatures call({
    Object? dictation = const $CopyWithPlaceholder(),
    Object? speech = const $CopyWithPlaceholder(),
    Object? outOfCredits = const $CopyWithPlaceholder(),
  }) {
    return WatchSelfFeatures(
      dictation: dictation == const $CopyWithPlaceholder() || dictation == null
          ? _value.dictation
          // ignore: cast_nullable_to_non_nullable
          : dictation as bool,
      speech: speech == const $CopyWithPlaceholder() || speech == null
          ? _value.speech
          // ignore: cast_nullable_to_non_nullable
          : speech as bool,
      outOfCredits:
          outOfCredits == const $CopyWithPlaceholder() || outOfCredits == null
          ? _value.outOfCredits
          // ignore: cast_nullable_to_non_nullable
          : outOfCredits as bool,
    );
  }
}

extension $WatchSelfFeaturesCopyWith on WatchSelfFeatures {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchSelfFeatures.copyWith(...)` or `instanceOfWatchSelfFeatures.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchSelfFeaturesCWProxy get copyWith =>
      _$WatchSelfFeaturesCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchSelfFeatures _$WatchSelfFeaturesFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WatchSelfFeatures', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['dictation', 'speech', 'out_of_credits'],
      );
      final val = WatchSelfFeatures(
        dictation: $checkedConvert('dictation', (v) => v as bool),
        speech: $checkedConvert('speech', (v) => v as bool),
        outOfCredits: $checkedConvert('out_of_credits', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'outOfCredits': 'out_of_credits'});

Map<String, dynamic> _$WatchSelfFeaturesToJson(WatchSelfFeatures instance) =>
    <String, dynamic>{
      'dictation': instance.dictation,
      'speech': instance.speech,
      'out_of_credits': instance.outOfCredits,
    };
