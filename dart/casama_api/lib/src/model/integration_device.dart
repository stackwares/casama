//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'integration_device.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class IntegrationDevice {
  /// Returns a new [IntegrationDevice] instance.
  IntegrationDevice({

    required  this.id,

    required  this.computerId,

    required  this.ownerUserId,

    required  this.label,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'computer_id',
    required: true,
    includeIfNull: true,
  )


  final String? computerId;



  @JsonKey(
    
    name: r'owner_user_id',
    required: true,
    includeIfNull: false,
  )


  final String ownerUserId;



  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  )


  final String label;





    @override
    bool operator ==(Object other) => identical(this, other) || other is IntegrationDevice &&
      other.id == id &&
      other.computerId == computerId &&
      other.ownerUserId == ownerUserId &&
      other.label == label;

    @override
    int get hashCode =>
        id.hashCode +
        (computerId == null ? 0 : computerId.hashCode) +
        ownerUserId.hashCode +
        label.hashCode;

  factory IntegrationDevice.fromJson(Map<String, dynamic> json) => _$IntegrationDeviceFromJson(json);

  Map<String, dynamic> toJson() => _$IntegrationDeviceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

