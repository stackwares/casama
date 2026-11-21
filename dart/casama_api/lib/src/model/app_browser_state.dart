//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/local_device.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_browser_state.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppBrowserState {
  /// Returns a new [AppBrowserState] instance.
  AppBrowserState({

    required  this.available,

    required  this.reason,

    required  this.device,
  });

  @JsonKey(
    
    name: r'available',
    required: true,
    includeIfNull: false,
  )


  final bool available;



      /// Why not: \"off\", \"not_a_tester\", \"system_off\", \"workspace_off\", \"unavailable\" (this server has no device connections)
  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: true,
  )


  final String? reason;



      /// This app install's browser in the workspace, when it is paired
  @JsonKey(
    
    name: r'device',
    required: true,
    includeIfNull: true,
  )


  final LocalDevice? device;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AppBrowserState &&
      other.available == available &&
      other.reason == reason &&
      other.device == device;

    @override
    int get hashCode =>
        available.hashCode +
        (reason == null ? 0 : reason.hashCode) +
        (device == null ? 0 : device.hashCode);

  factory AppBrowserState.fromJson(Map<String, dynamic> json) => _$AppBrowserStateFromJson(json);

  Map<String, dynamic> toJson() => _$AppBrowserStateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

