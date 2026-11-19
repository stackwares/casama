//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invite_code_preview.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InviteCodePreview {
  /// Returns a new [InviteCodePreview] instance.
  InviteCodePreview({

    required  this.kind,

    required  this.label,

    required  this.inviterName,

    required  this.available,

    required  this.welcomeUsd,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final InviteCodePreviewKindEnum kind;



  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: true,
  )


  final String? label;



  @JsonKey(
    
    name: r'inviter_name',
    required: true,
    includeIfNull: true,
  )


  final String? inviterName;



  @JsonKey(
    
    name: r'available',
    required: true,
    includeIfNull: false,
  )


  final bool available;



  @JsonKey(
    
    name: r'welcome_usd',
    required: true,
    includeIfNull: false,
  )


  final num welcomeUsd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InviteCodePreview &&
      other.kind == kind &&
      other.label == label &&
      other.inviterName == inviterName &&
      other.available == available &&
      other.welcomeUsd == welcomeUsd;

    @override
    int get hashCode =>
        kind.hashCode +
        (label == null ? 0 : label.hashCode) +
        (inviterName == null ? 0 : inviterName.hashCode) +
        available.hashCode +
        welcomeUsd.hashCode;

  factory InviteCodePreview.fromJson(Map<String, dynamic> json) => _$InviteCodePreviewFromJson(json);

  Map<String, dynamic> toJson() => _$InviteCodePreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum InviteCodePreviewKindEnum {
@JsonValue(r'personal')
personal(r'personal'),
@JsonValue(r'campaign')
campaign(r'campaign');

const InviteCodePreviewKindEnum(this.value);

final String value;

@override
String toString() => value;
}


