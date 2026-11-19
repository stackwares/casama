//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_bot_header.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchBotHeader {
  /// Returns a new [WatchBotHeader] instance.
  WatchBotHeader({

    required  this.id,

    required  this.name,

    required  this.avatar,

    required  this.status,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'avatar',
    required: true,
    includeIfNull: false,
  )


  final String avatar;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final WatchBotHeaderStatusEnum status;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchBotHeader &&
      other.id == id &&
      other.name == name &&
      other.avatar == avatar &&
      other.status == status;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        avatar.hashCode +
        status.hashCode;

  factory WatchBotHeader.fromJson(Map<String, dynamic> json) => _$WatchBotHeaderFromJson(json);

  Map<String, dynamic> toJson() => _$WatchBotHeaderToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum WatchBotHeaderStatusEnum {
@JsonValue(r'idle')
idle(r'idle'),
@JsonValue(r'working')
working(r'working'),
@JsonValue(r'waiting')
waiting(r'waiting'),
@JsonValue(r'disabled')
disabled(r'disabled');

const WatchBotHeaderStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


