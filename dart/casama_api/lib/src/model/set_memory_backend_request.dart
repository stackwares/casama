//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_memory_backend_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetMemoryBackendRequest {
  /// Returns a new [SetMemoryBackendRequest] instance.
  SetMemoryBackendRequest({

    required  this.provider,

    required  this.apiKey,

     this.baseUrl,

     this.workspace,

     this.copyExisting,
  });

  @JsonKey(
    
    name: r'provider',
    required: true,
    includeIfNull: false,
  )


  final SetMemoryBackendRequestProviderEnum provider;



  @JsonKey(
    
    name: r'api_key',
    required: true,
    includeIfNull: false,
  )


  final String apiKey;



  @JsonKey(
    
    name: r'base_url',
    required: false,
    includeIfNull: false,
  )


  final String? baseUrl;



  @JsonKey(
    
    name: r'workspace',
    required: false,
    includeIfNull: false,
  )


  final String? workspace;



  @JsonKey(
    
    name: r'copy_existing',
    required: false,
    includeIfNull: false,
  )


  final bool? copyExisting;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetMemoryBackendRequest &&
      other.provider == provider &&
      other.apiKey == apiKey &&
      other.baseUrl == baseUrl &&
      other.workspace == workspace &&
      other.copyExisting == copyExisting;

    @override
    int get hashCode =>
        provider.hashCode +
        apiKey.hashCode +
        baseUrl.hashCode +
        workspace.hashCode +
        copyExisting.hashCode;

  factory SetMemoryBackendRequest.fromJson(Map<String, dynamic> json) => _$SetMemoryBackendRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetMemoryBackendRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SetMemoryBackendRequestProviderEnum {
@JsonValue(r'honcho')
honcho(r'honcho'),
@JsonValue(r'supermemory')
supermemory(r'supermemory');

const SetMemoryBackendRequestProviderEnum(this.value);

final String value;

@override
String toString() => value;
}


