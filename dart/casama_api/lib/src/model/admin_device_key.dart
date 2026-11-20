//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_device_key.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminDeviceKey {
  /// Returns a new [AdminDeviceKey] instance.
  AdminDeviceKey({

    required  this.id,

    required  this.name,

    required  this.createdAt,

    required  this.lastUsedAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'last_used_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastUsedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminDeviceKey &&
      other.id == id &&
      other.name == name &&
      other.createdAt == createdAt &&
      other.lastUsedAt == lastUsedAt;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        createdAt.hashCode +
        (lastUsedAt == null ? 0 : lastUsedAt.hashCode);

  factory AdminDeviceKey.fromJson(Map<String, dynamic> json) => _$AdminDeviceKeyFromJson(json);

  Map<String, dynamic> toJson() => _$AdminDeviceKeyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

