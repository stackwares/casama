//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_page_watcher_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreatePageWatcherRequest {
  /// Returns a new [CreatePageWatcherRequest] instance.
  CreatePageWatcherRequest({

    required  this.botId,

    required  this.name,

    required  this.url,

     this.anchor,

     this.chars,

     this.condition,

     this.checkEveryMinutes,

     this.where,
  });

      /// The bot woken when the page changes
  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



      /// The page; the server reads public pages, your browser signed-in ones
  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



      /// Compare from this text on (a label just before the part that matters)
  @JsonKey(
    
    name: r'anchor',
    required: false,
    includeIfNull: false,
  )


  final String? anchor;



      /// How much after the anchor to compare (default 2,000 characters)
          // minimum: 20
          // maximum: 2000
  @JsonKey(
    
    name: r'chars',
    required: false,
    includeIfNull: false,
  )


  final int? chars;



      /// What counts as a match, in words (\"the price drops below $40\")
  @JsonKey(
    
    name: r'condition',
    required: false,
    includeIfNull: false,
  )


  final String? condition;



          // minimum: 15
          // maximum: 10080
  @JsonKey(
    
    name: r'check_every_minutes',
    required: false,
    includeIfNull: false,
  )


  final int? checkEveryMinutes;



      /// \"mine\": a signed-in page, read in your own browser whenever it's online (Phase 3); default \"server\" (public pages)
  @JsonKey(
    
    name: r'where',
    required: false,
    includeIfNull: false,
  )


  final CreatePageWatcherRequestWhereEnum? where;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreatePageWatcherRequest &&
      other.botId == botId &&
      other.name == name &&
      other.url == url &&
      other.anchor == anchor &&
      other.chars == chars &&
      other.condition == condition &&
      other.checkEveryMinutes == checkEveryMinutes &&
      other.where == where;

    @override
    int get hashCode =>
        botId.hashCode +
        name.hashCode +
        url.hashCode +
        anchor.hashCode +
        chars.hashCode +
        condition.hashCode +
        checkEveryMinutes.hashCode +
        where.hashCode;

  factory CreatePageWatcherRequest.fromJson(Map<String, dynamic> json) => _$CreatePageWatcherRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePageWatcherRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// \"mine\": a signed-in page, read in your own browser whenever it's online (Phase 3); default \"server\" (public pages)
enum CreatePageWatcherRequestWhereEnum {
    /// \"mine\": a signed-in page, read in your own browser whenever it's online (Phase 3); default \"server\" (public pages)
@JsonValue(r'server')
server(r'server'),
    /// \"mine\": a signed-in page, read in your own browser whenever it's online (Phase 3); default \"server\" (public pages)
@JsonValue(r'mine')
mine(r'mine');

const CreatePageWatcherRequestWhereEnum(this.value);

final String value;

@override
String toString() => value;
}


