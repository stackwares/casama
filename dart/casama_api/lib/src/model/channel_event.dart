//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'channel_event.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChannelEvent {
  /// Returns a new [ChannelEvent] instance.
  ChannelEvent({

    required  this.id,

    required  this.direction,

    required  this.status,

    required  this.sender,

    required  this.preview,

    required  this.detail,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'direction',
    required: true,
    includeIfNull: false,
  )


  final ChannelEventDirectionEnum direction;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final ChannelEventStatusEnum status;



  @JsonKey(
    
    name: r'sender',
    required: true,
    includeIfNull: true,
  )


  final String? sender;



  @JsonKey(
    
    name: r'preview',
    required: true,
    includeIfNull: true,
  )


  final String? preview;



  @JsonKey(
    
    name: r'detail',
    required: true,
    includeIfNull: true,
  )


  final String? detail;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ChannelEvent &&
      other.id == id &&
      other.direction == direction &&
      other.status == status &&
      other.sender == sender &&
      other.preview == preview &&
      other.detail == detail &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        direction.hashCode +
        status.hashCode +
        (sender == null ? 0 : sender.hashCode) +
        (preview == null ? 0 : preview.hashCode) +
        (detail == null ? 0 : detail.hashCode) +
        createdAt.hashCode;

  factory ChannelEvent.fromJson(Map<String, dynamic> json) => _$ChannelEventFromJson(json);

  Map<String, dynamic> toJson() => _$ChannelEventToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ChannelEventDirectionEnum {
@JsonValue(r'in')
in_(r'in'),
@JsonValue(r'out')
out_(r'out');

const ChannelEventDirectionEnum(this.value);

final String value;

@override
String toString() => value;
}



enum ChannelEventStatusEnum {
@JsonValue(r'accepted')
accepted(r'accepted'),
@JsonValue(r'ignored')
ignored(r'ignored'),
@JsonValue(r'routine')
routine(r'routine'),
@JsonValue(r'sent')
sent(r'sent'),
@JsonValue(r'failed')
failed(r'failed');

const ChannelEventStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


