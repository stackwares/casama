//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_browser_guard.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminBrowserGuard {
  /// Returns a new [AdminBrowserGuard] instance.
  AdminBrowserGuard({

    required  this.hosts,

    required  this.builtIn,
  });

  @JsonKey(
    
    name: r'hosts',
    required: true,
    includeIfNull: false,
  )


  final Map<String, List<String>> hosts;



  @JsonKey(
    
    name: r'built_in',
    required: true,
    includeIfNull: false,
  )


  final Map<String, List<String>> builtIn;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminBrowserGuard &&
      other.hosts == hosts &&
      other.builtIn == builtIn;

    @override
    int get hashCode =>
        hosts.hashCode +
        builtIn.hashCode;

  factory AdminBrowserGuard.fromJson(Map<String, dynamic> json) => _$AdminBrowserGuardFromJson(json);

  Map<String, dynamic> toJson() => _$AdminBrowserGuardToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

