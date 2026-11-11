//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ice_server.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class IceServer {
  /// Returns a new [IceServer] instance.
  IceServer({

    required  this.urls,

     this.username,

     this.credential,
  });

  @JsonKey(
    
    name: r'urls',
    required: true,
    includeIfNull: false,
  )


  final List<String> urls;



  @JsonKey(
    
    name: r'username',
    required: false,
    includeIfNull: false,
  )


  final String? username;



  @JsonKey(
    
    name: r'credential',
    required: false,
    includeIfNull: false,
  )


  final String? credential;





    @override
    bool operator ==(Object other) => identical(this, other) || other is IceServer &&
      other.urls == urls &&
      other.username == username &&
      other.credential == credential;

    @override
    int get hashCode =>
        urls.hashCode +
        username.hashCode +
        credential.hashCode;

  factory IceServer.fromJson(Map<String, dynamic> json) => _$IceServerFromJson(json);

  Map<String, dynamic> toJson() => _$IceServerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

