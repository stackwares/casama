//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_password_manager_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreatePasswordManagerRequest {
  /// Returns a new [CreatePasswordManagerRequest] instance.
  CreatePasswordManagerRequest({

    required  this.orgId,

    required  this.scope,

    required  this.provider,

    required  this.name,

    required  this.url,

    required  this.token,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'scope',
    required: true,
    includeIfNull: false,
  )


  final CreatePasswordManagerRequestScopeEnum scope;



  @JsonKey(
    
    name: r'provider',
    required: true,
    includeIfNull: false,
  )


  final CreatePasswordManagerRequestProviderEnum provider;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



  @JsonKey(
    
    name: r'token',
    required: true,
    includeIfNull: false,
  )


  final String token;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreatePasswordManagerRequest &&
      other.orgId == orgId &&
      other.scope == scope &&
      other.provider == provider &&
      other.name == name &&
      other.url == url &&
      other.token == token;

    @override
    int get hashCode =>
        orgId.hashCode +
        scope.hashCode +
        provider.hashCode +
        name.hashCode +
        url.hashCode +
        token.hashCode;

  factory CreatePasswordManagerRequest.fromJson(Map<String, dynamic> json) => _$CreatePasswordManagerRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePasswordManagerRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CreatePasswordManagerRequestScopeEnum {
@JsonValue(r'workspace')
workspace(r'workspace'),
@JsonValue(r'personal')
personal(r'personal');

const CreatePasswordManagerRequestScopeEnum(this.value);

final String value;

@override
String toString() => value;
}



enum CreatePasswordManagerRequestProviderEnum {
@JsonValue(r'1password')
n1password(r'1password'),
@JsonValue(r'bitwarden')
bitwarden(r'bitwarden');

const CreatePasswordManagerRequestProviderEnum(this.value);

final String value;

@override
String toString() => value;
}


