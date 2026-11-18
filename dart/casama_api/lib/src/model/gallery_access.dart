//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_access.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryAccess {
  /// Returns a new [GalleryAccess] instance.
  GalleryAccess({

     this.reads,

     this.writes,

     this.runsCode,

     this.computer,

     this.credits,
  });

  @JsonKey(
    
    name: r'reads',
    required: false,
    includeIfNull: false,
  )


  final List<String>? reads;



  @JsonKey(
    
    name: r'writes',
    required: false,
    includeIfNull: false,
  )


  final List<String>? writes;



  @JsonKey(
    
    name: r'runs_code',
    required: false,
    includeIfNull: false,
  )


  final bool? runsCode;



  @JsonKey(
    
    name: r'computer',
    required: false,
    includeIfNull: false,
  )


  final bool? computer;



  @JsonKey(
    
    name: r'credits',
    required: false,
    includeIfNull: false,
  )


  final GalleryAccessCreditsEnum? credits;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryAccess &&
      other.reads == reads &&
      other.writes == writes &&
      other.runsCode == runsCode &&
      other.computer == computer &&
      other.credits == credits;

    @override
    int get hashCode =>
        reads.hashCode +
        writes.hashCode +
        runsCode.hashCode +
        computer.hashCode +
        credits.hashCode;

  factory GalleryAccess.fromJson(Map<String, dynamic> json) => _$GalleryAccessFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryAccessToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GalleryAccessCreditsEnum {
@JsonValue(r'none')
none(r'none'),
@JsonValue(r'low')
low(r'low'),
@JsonValue(r'medium')
medium(r'medium'),
@JsonValue(r'high')
high(r'high');

const GalleryAccessCreditsEnum(this.value);

final String value;

@override
String toString() => value;
}


