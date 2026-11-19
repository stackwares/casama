//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_mention_ref.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppMentionRef {
  /// Returns a new [AppMentionRef] instance.
  AppMentionRef({

    required  this.integrationId,

     this.toolkit,
  });

  @JsonKey(
    
    name: r'integration_id',
    required: true,
    includeIfNull: false,
  )


  final String integrationId;



      /// Hub toolkit or app slug (Composio or Pipedream)
  @JsonKey(
    
    name: r'toolkit',
    required: false,
    includeIfNull: false,
  )


  final String? toolkit;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AppMentionRef &&
      other.integrationId == integrationId &&
      other.toolkit == toolkit;

    @override
    int get hashCode =>
        integrationId.hashCode +
        toolkit.hashCode;

  factory AppMentionRef.fromJson(Map<String, dynamic> json) => _$AppMentionRefFromJson(json);

  Map<String, dynamic> toJson() => _$AppMentionRefToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

