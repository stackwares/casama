//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/link_exchange.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'link_exchange_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LinkExchangeList {
  /// Returns a new [LinkExchangeList] instance.
  LinkExchangeList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<LinkExchange> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LinkExchangeList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory LinkExchangeList.fromJson(Map<String, dynamic> json) => _$LinkExchangeListFromJson(json);

  Map<String, dynamic> toJson() => _$LinkExchangeListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

