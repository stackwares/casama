//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/provider_app.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'provider_app_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProviderAppList {
  /// Returns a new [ProviderAppList] instance.
  ProviderAppList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<ProviderApp> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ProviderAppList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ProviderAppList.fromJson(Map<String, dynamic> json) => _$ProviderAppListFromJson(json);

  Map<String, dynamic> toJson() => _$ProviderAppListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

