//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'link_exchange.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LinkExchange {
  /// Returns a new [LinkExchange] instance.
  LinkExchange({

    required  this.id,

    required  this.direction,

    required  this.request,

    required  this.response,

    required  this.status,

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


  final LinkExchangeDirectionEnum direction;



  @JsonKey(
    
    name: r'request',
    required: true,
    includeIfNull: false,
  )


  final String request;



  @JsonKey(
    
    name: r'response',
    required: true,
    includeIfNull: true,
  )


  final String? response;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final LinkExchangeStatusEnum status;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LinkExchange &&
      other.id == id &&
      other.direction == direction &&
      other.request == request &&
      other.response == response &&
      other.status == status &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        direction.hashCode +
        request.hashCode +
        (response == null ? 0 : response.hashCode) +
        status.hashCode +
        createdAt.hashCode;

  factory LinkExchange.fromJson(Map<String, dynamic> json) => _$LinkExchangeFromJson(json);

  Map<String, dynamic> toJson() => _$LinkExchangeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum LinkExchangeDirectionEnum {
@JsonValue(r'out')
out_(r'out'),
@JsonValue(r'in')
in_(r'in');

const LinkExchangeDirectionEnum(this.value);

final String value;

@override
String toString() => value;
}



enum LinkExchangeStatusEnum {
@JsonValue(r'working')
working(r'working'),
@JsonValue(r'answered')
answered(r'answered'),
@JsonValue(r'failed')
failed(r'failed');

const LinkExchangeStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


