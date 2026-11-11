// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dismiss_suggestion_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DismissSuggestionRequestCWProxy {
  DismissSuggestionRequest dontSuggestAgain(bool? dontSuggestAgain);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DismissSuggestionRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DismissSuggestionRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  DismissSuggestionRequest call({bool? dontSuggestAgain});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDismissSuggestionRequest.copyWith(...)` or call `instanceOfDismissSuggestionRequest.copyWith.fieldName(value)` for a single field.
class _$DismissSuggestionRequestCWProxyImpl
    implements _$DismissSuggestionRequestCWProxy {
  const _$DismissSuggestionRequestCWProxyImpl(this._value);

  final DismissSuggestionRequest _value;

  @override
  DismissSuggestionRequest dontSuggestAgain(bool? dontSuggestAgain) =>
      call(dontSuggestAgain: dontSuggestAgain);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DismissSuggestionRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DismissSuggestionRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DismissSuggestionRequest call({
    Object? dontSuggestAgain = const $CopyWithPlaceholder(),
  }) {
    return DismissSuggestionRequest(
      dontSuggestAgain: dontSuggestAgain == const $CopyWithPlaceholder()
          ? _value.dontSuggestAgain
          // ignore: cast_nullable_to_non_nullable
          : dontSuggestAgain as bool?,
    );
  }
}

extension $DismissSuggestionRequestCopyWith on DismissSuggestionRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDismissSuggestionRequest.copyWith(...)` or `instanceOfDismissSuggestionRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DismissSuggestionRequestCWProxy get copyWith =>
      _$DismissSuggestionRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DismissSuggestionRequest _$DismissSuggestionRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DismissSuggestionRequest', json, ($checkedConvert) {
  final val = DismissSuggestionRequest(
    dontSuggestAgain: $checkedConvert(
      'dont_suggest_again',
      (v) => v as bool? ?? false,
    ),
  );
  return val;
}, fieldKeyMap: const {'dontSuggestAgain': 'dont_suggest_again'});

Map<String, dynamic> _$DismissSuggestionRequestToJson(
  DismissSuggestionRequest instance,
) => <String, dynamic>{'dont_suggest_again': ?instance.dontSuggestAgain};
