//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'domain_event.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DomainEvent {
  /// Returns a new [DomainEvent] instance.
  DomainEvent({

    required  this.kind,

    required  this.detail,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final String kind;



  @JsonKey(
    
    name: r'detail',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> detail;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DomainEvent &&
      other.kind == kind &&
      other.detail == detail &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        kind.hashCode +
        detail.hashCode +
        createdAt.hashCode;

  factory DomainEvent.fromJson(Map<String, dynamic> json) => _$DomainEventFromJson(json);

  Map<String, dynamic> toJson() => _$DomainEventToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

