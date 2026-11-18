//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/domain_contact.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'domain_contact_state.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DomainContactState {
  /// Returns a new [DomainContactState] instance.
  DomainContactState({

    required  this.contact,

    required  this.defaultEmail,
  });

  @JsonKey(
    
    name: r'contact',
    required: true,
    includeIfNull: true,
  )


  final DomainContact? contact;



  @JsonKey(
    
    name: r'default_email',
    required: true,
    includeIfNull: true,
  )


  final String? defaultEmail;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DomainContactState &&
      other.contact == contact &&
      other.defaultEmail == defaultEmail;

    @override
    int get hashCode =>
        (contact == null ? 0 : contact.hashCode) +
        (defaultEmail == null ? 0 : defaultEmail.hashCode);

  factory DomainContactState.fromJson(Map<String, dynamic> json) => _$DomainContactStateFromJson(json);

  Map<String, dynamic> toJson() => _$DomainContactStateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

