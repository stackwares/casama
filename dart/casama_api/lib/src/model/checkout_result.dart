//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'checkout_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CheckoutResult {
  /// Returns a new [CheckoutResult] instance.
  CheckoutResult({

    required  this.url,

     this.changed,
  });

  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



  @JsonKey(
    
    name: r'changed',
    required: false,
    includeIfNull: false,
  )


  final bool? changed;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CheckoutResult &&
      other.url == url &&
      other.changed == changed;

    @override
    int get hashCode =>
        url.hashCode +
        changed.hashCode;

  factory CheckoutResult.fromJson(Map<String, dynamic> json) => _$CheckoutResultFromJson(json);

  Map<String, dynamic> toJson() => _$CheckoutResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

