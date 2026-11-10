//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'local_capabilities.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LocalCapabilities {
  /// Returns a new [LocalCapabilities] instance.
  LocalCapabilities({

     this.shell,

     this.files,

     this.browser,

     this.desktop,

     this.mcp,
  });

  @JsonKey(
    
    name: r'shell',
    required: false,
    includeIfNull: false,
  )


  final bool? shell;



  @JsonKey(
    
    name: r'files',
    required: false,
    includeIfNull: false,
  )


  final bool? files;



  @JsonKey(
    
    name: r'browser',
    required: false,
    includeIfNull: false,
  )


  final bool? browser;



  @JsonKey(
    
    name: r'desktop',
    required: false,
    includeIfNull: false,
  )


  final bool? desktop;



  @JsonKey(
    
    name: r'mcp',
    required: false,
    includeIfNull: false,
  )


  final bool? mcp;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LocalCapabilities &&
      other.shell == shell &&
      other.files == files &&
      other.browser == browser &&
      other.desktop == desktop &&
      other.mcp == mcp;

    @override
    int get hashCode =>
        shell.hashCode +
        files.hashCode +
        browser.hashCode +
        desktop.hashCode +
        mcp.hashCode;

  factory LocalCapabilities.fromJson(Map<String, dynamic> json) => _$LocalCapabilitiesFromJson(json);

  Map<String, dynamic> toJson() => _$LocalCapabilitiesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

