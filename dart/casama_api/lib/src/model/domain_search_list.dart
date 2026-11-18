//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/domain_search_result.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'domain_search_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DomainSearchList {
  /// Returns a new [DomainSearchList] instance.
  DomainSearchList({

    required  this.query,

    required  this.items,

    required  this.tlds,
  });

  @JsonKey(
    
    name: r'query',
    required: true,
    includeIfNull: false,
  )


  final String query;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<DomainSearchResult> items;



  @JsonKey(
    
    name: r'tlds',
    required: true,
    includeIfNull: false,
  )


  final List<String> tlds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DomainSearchList &&
      other.query == query &&
      other.items == items &&
      other.tlds == tlds;

    @override
    int get hashCode =>
        query.hashCode +
        items.hashCode +
        tlds.hashCode;

  factory DomainSearchList.fromJson(Map<String, dynamic> json) => _$DomainSearchListFromJson(json);

  Map<String, dynamic> toJson() => _$DomainSearchListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

