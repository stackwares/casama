//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'remote_app_config_maintenance.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RemoteAppConfigMaintenance {
  /// Returns a new [RemoteAppConfigMaintenance] instance.
  RemoteAppConfigMaintenance({

    required  this.message,
  });

  @JsonKey(
    
    name: r'message',
    required: true,
    includeIfNull: false,
  )


  final String message;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RemoteAppConfigMaintenance &&
      other.message == message;

    @override
    int get hashCode =>
        message.hashCode;

  factory RemoteAppConfigMaintenance.fromJson(Map<String, dynamic> json) => _$RemoteAppConfigMaintenanceFromJson(json);

  Map<String, dynamic> toJson() => _$RemoteAppConfigMaintenanceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

