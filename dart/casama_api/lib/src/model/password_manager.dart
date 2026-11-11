//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'password_manager.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PasswordManager {
  /// Returns a new [PasswordManager] instance.
  PasswordManager({

    required  this.id,

    required  this.scope,

    required  this.provider,

    required  this.name,

    required  this.url,

    required  this.allowedVaults,

    required  this.allowedBotIds,

    required  this.status,

    required  this.lastError,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'scope',
    required: true,
    includeIfNull: false,
  )


  final PasswordManagerScopeEnum scope;



  @JsonKey(
    
    name: r'provider',
    required: true,
    includeIfNull: false,
  )


  final PasswordManagerProviderEnum provider;



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
    
    name: r'allowed_vaults',
    required: true,
    includeIfNull: false,
  )


  final List<String> allowedVaults;



  @JsonKey(
    
    name: r'allowed_bot_ids',
    required: true,
    includeIfNull: true,
  )


  final List<String>? allowedBotIds;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final PasswordManagerStatusEnum status;



  @JsonKey(
    
    name: r'last_error',
    required: true,
    includeIfNull: true,
  )


  final String? lastError;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PasswordManager &&
      other.id == id &&
      other.scope == scope &&
      other.provider == provider &&
      other.name == name &&
      other.url == url &&
      other.allowedVaults == allowedVaults &&
      other.allowedBotIds == allowedBotIds &&
      other.status == status &&
      other.lastError == lastError &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        scope.hashCode +
        provider.hashCode +
        name.hashCode +
        url.hashCode +
        allowedVaults.hashCode +
        (allowedBotIds == null ? 0 : allowedBotIds.hashCode) +
        status.hashCode +
        (lastError == null ? 0 : lastError.hashCode) +
        createdAt.hashCode;

  factory PasswordManager.fromJson(Map<String, dynamic> json) => _$PasswordManagerFromJson(json);

  Map<String, dynamic> toJson() => _$PasswordManagerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PasswordManagerScopeEnum {
@JsonValue(r'workspace')
workspace(r'workspace'),
@JsonValue(r'personal')
personal(r'personal');

const PasswordManagerScopeEnum(this.value);

final String value;

@override
String toString() => value;
}



enum PasswordManagerProviderEnum {
@JsonValue(r'1password')
n1password(r'1password'),
@JsonValue(r'bitwarden')
bitwarden(r'bitwarden');

const PasswordManagerProviderEnum(this.value);

final String value;

@override
String toString() => value;
}



enum PasswordManagerStatusEnum {
@JsonValue(r'ok')
ok(r'ok'),
@JsonValue(r'error')
error(r'error');

const PasswordManagerStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


