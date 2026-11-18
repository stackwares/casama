//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/pack_item_ref.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_pack_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdatePackRequest {
  /// Returns a new [UpdatePackRequest] instance.
  UpdatePackRequest({

    required  this.commit,

     this.takeTheirs,

     this.confirmReach,

     this.secrets,

     this.settings,
  });

  @JsonKey(
    
    name: r'commit',
    required: true,
    includeIfNull: false,
  )


  final String commit;



      /// Edited items to replace with the pack's version anyway
  @JsonKey(
    
    name: r'take_theirs',
    required: false,
    includeIfNull: false,
  )


  final List<PackItemRef>? takeTheirs;



      /// Required when the update reaches further (new hosts, secrets or servers)
  @JsonKey(
    
    name: r'confirm_reach',
    required: false,
    includeIfNull: false,
  )


  final bool? confirmReach;



  @JsonKey(
    
    name: r'secrets',
    required: false,
    includeIfNull: false,
  )


  final Map<String, String>? secrets;



  @JsonKey(
    
    name: r'settings',
    required: false,
    includeIfNull: false,
  )


  final Map<String, String>? settings;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdatePackRequest &&
      other.commit == commit &&
      other.takeTheirs == takeTheirs &&
      other.confirmReach == confirmReach &&
      other.secrets == secrets &&
      other.settings == settings;

    @override
    int get hashCode =>
        commit.hashCode +
        takeTheirs.hashCode +
        confirmReach.hashCode +
        secrets.hashCode +
        settings.hashCode;

  factory UpdatePackRequest.fromJson(Map<String, dynamic> json) => _$UpdatePackRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePackRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

