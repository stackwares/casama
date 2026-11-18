//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/bot_page.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_page_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdatePageResponse {
  /// Returns a new [UpdatePageResponse] instance.
  UpdatePageResponse({

    required  this.page,

    required  this.publicUrl,
  });

  @JsonKey(
    
    name: r'page',
    required: true,
    includeIfNull: false,
  )


  final BotPage page;



  @JsonKey(
    
    name: r'public_url',
    required: true,
    includeIfNull: true,
  )


  final String? publicUrl;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdatePageResponse &&
      other.page == page &&
      other.publicUrl == publicUrl;

    @override
    int get hashCode =>
        page.hashCode +
        (publicUrl == null ? 0 : publicUrl.hashCode);

  factory UpdatePageResponse.fromJson(Map<String, dynamic> json) => _$UpdatePageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePageResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

