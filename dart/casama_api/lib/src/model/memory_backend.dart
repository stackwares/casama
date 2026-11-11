//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'memory_backend.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MemoryBackend {
  /// Returns a new [MemoryBackend] instance.
  MemoryBackend({

    required  this.provider,

    required  this.baseUrl,

    required  this.workspace,

    required  this.updatedAt,
  });

  @JsonKey(
    
    name: r'provider',
    required: true,
    includeIfNull: false,
  )


  final MemoryBackendProviderEnum provider;



  @JsonKey(
    
    name: r'base_url',
    required: true,
    includeIfNull: true,
  )


  final String? baseUrl;



  @JsonKey(
    
    name: r'workspace',
    required: true,
    includeIfNull: true,
  )


  final String? workspace;



  @JsonKey(
    
    name: r'updated_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? updatedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MemoryBackend &&
      other.provider == provider &&
      other.baseUrl == baseUrl &&
      other.workspace == workspace &&
      other.updatedAt == updatedAt;

    @override
    int get hashCode =>
        provider.hashCode +
        (baseUrl == null ? 0 : baseUrl.hashCode) +
        (workspace == null ? 0 : workspace.hashCode) +
        (updatedAt == null ? 0 : updatedAt.hashCode);

  factory MemoryBackend.fromJson(Map<String, dynamic> json) => _$MemoryBackendFromJson(json);

  Map<String, dynamic> toJson() => _$MemoryBackendToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum MemoryBackendProviderEnum {
@JsonValue(r'postgres')
postgres(r'postgres'),
@JsonValue(r'honcho')
honcho(r'honcho'),
@JsonValue(r'supermemory')
supermemory(r'supermemory');

const MemoryBackendProviderEnum(this.value);

final String value;

@override
String toString() => value;
}


