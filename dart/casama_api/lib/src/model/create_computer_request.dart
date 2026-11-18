//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_computer_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateComputerRequest {
  /// Returns a new [CreateComputerRequest] instance.
  CreateComputerRequest({

    required  this.orgId,

    required  this.name,

    required  this.kind,

     this.ownerBotId,

     this.profile,

     this.provider,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final CreateComputerRequestKindEnum kind;



      /// Required for private computers
  @JsonKey(
    
    name: r'owner_bot_id',
    required: false,
    includeIfNull: false,
  )


  final String? ownerBotId;



  @JsonKey(
    
    name: r'profile',
    required: false,
    includeIfNull: false,
  )


  final CreateComputerRequestProfileEnum? profile;



      /// Hosted providers must be configured on the supervisor
  @JsonKey(
    
    name: r'provider',
    required: false,
    includeIfNull: false,
  )


  final CreateComputerRequestProviderEnum? provider;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateComputerRequest &&
      other.orgId == orgId &&
      other.name == name &&
      other.kind == kind &&
      other.ownerBotId == ownerBotId &&
      other.profile == profile &&
      other.provider == provider;

    @override
    int get hashCode =>
        orgId.hashCode +
        name.hashCode +
        kind.hashCode +
        ownerBotId.hashCode +
        profile.hashCode +
        provider.hashCode;

  factory CreateComputerRequest.fromJson(Map<String, dynamic> json) => _$CreateComputerRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateComputerRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CreateComputerRequestKindEnum {
@JsonValue(r'team')
team(r'team'),
@JsonValue(r'private')
private(r'private');

const CreateComputerRequestKindEnum(this.value);

final String value;

@override
String toString() => value;
}



enum CreateComputerRequestProfileEnum {
@JsonValue(r'headless')
headless(r'headless'),
@JsonValue(r'desktop')
desktop(r'desktop');

const CreateComputerRequestProfileEnum(this.value);

final String value;

@override
String toString() => value;
}


/// Hosted providers must be configured on the supervisor
enum CreateComputerRequestProviderEnum {
    /// Hosted providers must be configured on the supervisor
@JsonValue(r'docker')
docker(r'docker'),
    /// Hosted providers must be configured on the supervisor
@JsonValue(r'e2b')
e2b(r'e2b'),
    /// Hosted providers must be configured on the supervisor
@JsonValue(r'daytona')
daytona(r'daytona'),
    /// Hosted providers must be configured on the supervisor
@JsonValue(r'casama-cloud')
casamaCloud(r'casama-cloud'),
    /// Hosted providers must be configured on the supervisor
@JsonValue(r'novita')
novita(r'novita'),
    /// Hosted providers must be configured on the supervisor
@JsonValue(r'kubernetes')
kubernetes(r'kubernetes'),
    /// Hosted providers must be configured on the supervisor
@JsonValue(r'incus')
incus(r'incus'),
    /// Hosted providers must be configured on the supervisor
@JsonValue(r'boat')
boat(r'boat'),
    /// Hosted providers must be configured on the supervisor
@JsonValue(r'railway')
railway(r'railway');

const CreateComputerRequestProviderEnum(this.value);

final String value;

@override
String toString() => value;
}


