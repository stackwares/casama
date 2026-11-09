//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/model_option.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model_option_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ModelOptionList {
  /// Returns a new [ModelOptionList] instance.
  ModelOptionList({

    required  this.items,

    required  this.source_,

     this.error,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<ModelOption> items;



      /// live: the provider's own list; featured: Kasama's short list (provider unreachable or fixture mode)
  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final ModelOptionListSource_Enum source_;



  @JsonKey(
    
    name: r'error',
    required: false,
    includeIfNull: false,
  )


  final String? error;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ModelOptionList &&
      other.items == items &&
      other.source_ == source_ &&
      other.error == error;

    @override
    int get hashCode =>
        items.hashCode +
        source_.hashCode +
        error.hashCode;

  factory ModelOptionList.fromJson(Map<String, dynamic> json) => _$ModelOptionListFromJson(json);

  Map<String, dynamic> toJson() => _$ModelOptionListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// live: the provider's own list; featured: Kasama's short list (provider unreachable or fixture mode)
enum ModelOptionListSource_Enum {
    /// live: the provider's own list; featured: Kasama's short list (provider unreachable or fixture mode)
@JsonValue(r'live')
live(r'live'),
    /// live: the provider's own list; featured: Kasama's short list (provider unreachable or fixture mode)
@JsonValue(r'featured')
featured(r'featured');

const ModelOptionListSource_Enum(this.value);

final String value;

@override
String toString() => value;
}


