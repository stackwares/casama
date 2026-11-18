//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'domain_contact.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DomainContact {
  /// Returns a new [DomainContact] instance.
  DomainContact({

    required  this.firstName,

    required  this.lastName,

     this.organization,

    required  this.address1,

     this.address2,

    required  this.city,

    required  this.state,

    required  this.zip,

    required  this.country,

    required  this.phone,

    required  this.email,
  });

  @JsonKey(
    
    name: r'first_name',
    required: true,
    includeIfNull: false,
  )


  final String firstName;



  @JsonKey(
    
    name: r'last_name',
    required: true,
    includeIfNull: false,
  )


  final String lastName;



  @JsonKey(
    
    name: r'organization',
    required: false,
    includeIfNull: false,
  )


  final String? organization;



  @JsonKey(
    
    name: r'address1',
    required: true,
    includeIfNull: false,
  )


  final String address1;



  @JsonKey(
    
    name: r'address2',
    required: false,
    includeIfNull: false,
  )


  final String? address2;



  @JsonKey(
    
    name: r'city',
    required: true,
    includeIfNull: false,
  )


  final String city;



  @JsonKey(
    
    name: r'state',
    required: true,
    includeIfNull: false,
  )


  final String state;



  @JsonKey(
    
    name: r'zip',
    required: true,
    includeIfNull: false,
  )


  final String zip;



  @JsonKey(
    
    name: r'country',
    required: true,
    includeIfNull: false,
  )


  final String country;



  @JsonKey(
    
    name: r'phone',
    required: true,
    includeIfNull: false,
  )


  final String phone;



  @JsonKey(
    
    name: r'email',
    required: true,
    includeIfNull: false,
  )


  final String email;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DomainContact &&
      other.firstName == firstName &&
      other.lastName == lastName &&
      other.organization == organization &&
      other.address1 == address1 &&
      other.address2 == address2 &&
      other.city == city &&
      other.state == state &&
      other.zip == zip &&
      other.country == country &&
      other.phone == phone &&
      other.email == email;

    @override
    int get hashCode =>
        firstName.hashCode +
        lastName.hashCode +
        (organization == null ? 0 : organization.hashCode) +
        address1.hashCode +
        (address2 == null ? 0 : address2.hashCode) +
        city.hashCode +
        state.hashCode +
        zip.hashCode +
        country.hashCode +
        phone.hashCode +
        email.hashCode;

  factory DomainContact.fromJson(Map<String, dynamic> json) => _$DomainContactFromJson(json);

  Map<String, dynamic> toJson() => _$DomainContactToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

