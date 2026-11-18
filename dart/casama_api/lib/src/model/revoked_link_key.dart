//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'revoked_link_key.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RevokedLinkKey {
  /// Returns a new [RevokedLinkKey] instance.
  RevokedLinkKey({

    required  this.revoked,
  });

  @JsonKey(
    
    name: r'revoked',
    required: true,
    includeIfNull: false,
  )


  final String revoked;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RevokedLinkKey &&
      other.revoked == revoked;

    @override
    int get hashCode =>
        revoked.hashCode;

  factory RevokedLinkKey.fromJson(Map<String, dynamic> json) => _$RevokedLinkKeyFromJson(json);

  Map<String, dynamic> toJson() => _$RevokedLinkKeyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

