//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'apple_sign_in_token_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppleSignInTokenResult {
  /// Returns a new [AppleSignInTokenResult] instance.
  AppleSignInTokenResult({

    required  this.stored,
  });

      /// False when this server doesn't revoke Apple tokens (no Sign in with Apple key)
  @JsonKey(
    
    name: r'stored',
    required: true,
    includeIfNull: false,
  )


  final bool stored;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AppleSignInTokenResult &&
      other.stored == stored;

    @override
    int get hashCode =>
        stored.hashCode;

  factory AppleSignInTokenResult.fromJson(Map<String, dynamic> json) => _$AppleSignInTokenResultFromJson(json);

  Map<String, dynamic> toJson() => _$AppleSignInTokenResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

