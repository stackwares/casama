//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_payment_settings_request_cardholder.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetPaymentSettingsRequestCardholder {
  /// Returns a new [SetPaymentSettingsRequestCardholder] instance.
  SetPaymentSettingsRequestCardholder({

    required  this.name,

    required  this.email,

    required  this.line1,

    required  this.city,

     this.state,

    required  this.postalCode,

    required  this.country,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'email',
    required: true,
    includeIfNull: false,
  )


  final String email;



  @JsonKey(
    
    name: r'line1',
    required: true,
    includeIfNull: false,
  )


  final String line1;



  @JsonKey(
    
    name: r'city',
    required: true,
    includeIfNull: false,
  )


  final String city;



  @JsonKey(
    
    name: r'state',
    required: false,
    includeIfNull: false,
  )


  final String? state;



  @JsonKey(
    
    name: r'postal_code',
    required: true,
    includeIfNull: false,
  )


  final String postalCode;



  @JsonKey(
    
    name: r'country',
    required: true,
    includeIfNull: false,
  )


  final String country;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetPaymentSettingsRequestCardholder &&
      other.name == name &&
      other.email == email &&
      other.line1 == line1 &&
      other.city == city &&
      other.state == state &&
      other.postalCode == postalCode &&
      other.country == country;

    @override
    int get hashCode =>
        name.hashCode +
        email.hashCode +
        line1.hashCode +
        city.hashCode +
        state.hashCode +
        postalCode.hashCode +
        country.hashCode;

  factory SetPaymentSettingsRequestCardholder.fromJson(Map<String, dynamic> json) => _$SetPaymentSettingsRequestCardholderFromJson(json);

  Map<String, dynamic> toJson() => _$SetPaymentSettingsRequestCardholderToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

