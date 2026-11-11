//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_computer_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateComputerRequest {
  /// Returns a new [UpdateComputerRequest] instance.
  UpdateComputerRequest({

     this.name,

     this.profile,

     this.maxDesktops,
  });

  @JsonKey(
    
    name: r'name',
    required: false,
    includeIfNull: false,
  )


  final String? name;



      /// Takes effect on the next start (a running computer restarts)
  @JsonKey(
    
    name: r'profile',
    required: false,
    includeIfNull: false,
  )


  final UpdateComputerRequestProfileEnum? profile;



      /// Team computers only
          // minimum: 1
          // maximum: 10
  @JsonKey(
    
    name: r'max_desktops',
    required: false,
    includeIfNull: false,
  )


  final int? maxDesktops;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateComputerRequest &&
      other.name == name &&
      other.profile == profile &&
      other.maxDesktops == maxDesktops;

    @override
    int get hashCode =>
        name.hashCode +
        profile.hashCode +
        maxDesktops.hashCode;

  factory UpdateComputerRequest.fromJson(Map<String, dynamic> json) => _$UpdateComputerRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateComputerRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// Takes effect on the next start (a running computer restarts)
enum UpdateComputerRequestProfileEnum {
    /// Takes effect on the next start (a running computer restarts)
@JsonValue(r'headless')
headless(r'headless'),
    /// Takes effect on the next start (a running computer restarts)
@JsonValue(r'desktop')
desktop(r'desktop');

const UpdateComputerRequestProfileEnum(this.value);

final String value;

@override
String toString() => value;
}


