//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_password_manager_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdatePasswordManagerRequest {
  /// Returns a new [UpdatePasswordManagerRequest] instance.
  UpdatePasswordManagerRequest({

    required  this.allowedVaults,

     this.allowedBotIds,
  });

  @JsonKey(
    
    name: r'allowed_vaults',
    required: true,
    includeIfNull: false,
  )


  final List<String> allowedVaults;



  @JsonKey(
    
    name: r'allowed_bot_ids',
    required: false,
    includeIfNull: false,
  )


  final List<String>? allowedBotIds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdatePasswordManagerRequest &&
      other.allowedVaults == allowedVaults &&
      other.allowedBotIds == allowedBotIds;

    @override
    int get hashCode =>
        allowedVaults.hashCode +
        (allowedBotIds == null ? 0 : allowedBotIds.hashCode);

  factory UpdatePasswordManagerRequest.fromJson(Map<String, dynamic> json) => _$UpdatePasswordManagerRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePasswordManagerRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

