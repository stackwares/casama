//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/site.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'site_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SiteList {
  /// Returns a new [SiteList] instance.
  SiteList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Site> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SiteList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory SiteList.fromJson(Map<String, dynamic> json) => _$SiteListFromJson(json);

  Map<String, dynamic> toJson() => _$SiteListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

