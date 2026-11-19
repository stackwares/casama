//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'waitlist_stats_by_source_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WaitlistStatsBySourceInner {
  /// Returns a new [WaitlistStatsBySourceInner] instance.
  WaitlistStatsBySourceInner({

    required  this.key,

    required  this.listed,

    required  this.admitted,

    required  this.joined,

    required  this.firstChat,
  });

  @JsonKey(
    
    name: r'key',
    required: true,
    includeIfNull: false,
  )


  final String key;



  @JsonKey(
    
    name: r'listed',
    required: true,
    includeIfNull: false,
  )


  final int listed;



  @JsonKey(
    
    name: r'admitted',
    required: true,
    includeIfNull: false,
  )


  final int admitted;



  @JsonKey(
    
    name: r'joined',
    required: true,
    includeIfNull: false,
  )


  final int joined;



  @JsonKey(
    
    name: r'first_chat',
    required: true,
    includeIfNull: false,
  )


  final int firstChat;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WaitlistStatsBySourceInner &&
      other.key == key &&
      other.listed == listed &&
      other.admitted == admitted &&
      other.joined == joined &&
      other.firstChat == firstChat;

    @override
    int get hashCode =>
        key.hashCode +
        listed.hashCode +
        admitted.hashCode +
        joined.hashCode +
        firstChat.hashCode;

  factory WaitlistStatsBySourceInner.fromJson(Map<String, dynamic> json) => _$WaitlistStatsBySourceInnerFromJson(json);

  Map<String, dynamic> toJson() => _$WaitlistStatsBySourceInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

