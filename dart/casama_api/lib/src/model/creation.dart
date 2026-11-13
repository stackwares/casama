//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/creation_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'creation.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Creation {
  /// Returns a new [Creation] instance.
  Creation({

    required  this.id,

    required  this.orgId,

    required  this.botId,

    required  this.botName,

    required  this.madeFor,

    required  this.conversationId,

    required  this.runId,

    required  this.kind,

    required  this.label,

    required  this.title,

    required  this.pageId,

    required  this.mediaId,

    required  this.mime,

    required  this.size,

    required  this.width,

    required  this.height,

    required  this.durationS,

    required  this.hasCover,

    required  this.hasPreview,

    required  this.version,

    required  this.visibility,

    required  this.pinned,

    required  this.lastOpenedAt,

    required  this.canChange,

     this.publicUrl,

    required  this.deletedAt,

    required  this.createdAt,

    required  this.updatedAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: true,
  )


  final String? botId;



  @JsonKey(
    
    name: r'bot_name',
    required: true,
    includeIfNull: true,
  )


  final String? botName;



  @JsonKey(
    
    name: r'made_for',
    required: true,
    includeIfNull: true,
  )


  final String? madeFor;



  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: true,
  )


  final String? conversationId;



  @JsonKey(
    
    name: r'run_id',
    required: true,
    includeIfNull: true,
  )


  final String? runId;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final CreationKind kind;



      /// The bot's word for it: Site, Game, Report…
  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: true,
  )


  final String? label;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'page_id',
    required: true,
    includeIfNull: true,
  )


  final String? pageId;



  @JsonKey(
    
    name: r'media_id',
    required: true,
    includeIfNull: true,
  )


  final String? mediaId;



  @JsonKey(
    
    name: r'mime',
    required: true,
    includeIfNull: true,
  )


  final String? mime;



  @JsonKey(
    
    name: r'size',
    required: true,
    includeIfNull: false,
  )


  final int size;



  @JsonKey(
    
    name: r'width',
    required: true,
    includeIfNull: true,
  )


  final int? width;



  @JsonKey(
    
    name: r'height',
    required: true,
    includeIfNull: true,
  )


  final int? height;



  @JsonKey(
    
    name: r'duration_s',
    required: true,
    includeIfNull: true,
  )


  final num? durationS;



      /// GET /v1/creations/{id}/cover returns a picture; otherwise the app draws one
  @JsonKey(
    
    name: r'has_cover',
    required: true,
    includeIfNull: false,
  )


  final bool hasCover;



      /// GET /v1/creations/{id}/preview returns a PDF of it (documents; D-280)
  @JsonKey(
    
    name: r'has_preview',
    required: true,
    includeIfNull: false,
  )


  final bool hasPreview;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;



      /// Who can open it (D-281); a page's follows the page
  @JsonKey(
    
    name: r'visibility',
    required: true,
    includeIfNull: false,
  )


  final CreationVisibilityEnum visibility;



      /// Pinned by the person asking
  @JsonKey(
    
    name: r'pinned',
    required: true,
    includeIfNull: false,
  )


  final bool pinned;



  @JsonKey(
    
    name: r'last_opened_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastOpenedAt;



  @JsonKey(
    
    name: r'can_change',
    required: true,
    includeIfNull: false,
  )


  final bool canChange;



      /// The public link, only in the answer that made it public (D-281)
  @JsonKey(
    
    name: r'public_url',
    required: false,
    includeIfNull: false,
  )


  final String? publicUrl;



  @JsonKey(
    
    name: r'deleted_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? deletedAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime updatedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Creation &&
      other.id == id &&
      other.orgId == orgId &&
      other.botId == botId &&
      other.botName == botName &&
      other.madeFor == madeFor &&
      other.conversationId == conversationId &&
      other.runId == runId &&
      other.kind == kind &&
      other.label == label &&
      other.title == title &&
      other.pageId == pageId &&
      other.mediaId == mediaId &&
      other.mime == mime &&
      other.size == size &&
      other.width == width &&
      other.height == height &&
      other.durationS == durationS &&
      other.hasCover == hasCover &&
      other.hasPreview == hasPreview &&
      other.version == version &&
      other.visibility == visibility &&
      other.pinned == pinned &&
      other.lastOpenedAt == lastOpenedAt &&
      other.canChange == canChange &&
      other.publicUrl == publicUrl &&
      other.deletedAt == deletedAt &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        (botId == null ? 0 : botId.hashCode) +
        (botName == null ? 0 : botName.hashCode) +
        (madeFor == null ? 0 : madeFor.hashCode) +
        (conversationId == null ? 0 : conversationId.hashCode) +
        (runId == null ? 0 : runId.hashCode) +
        kind.hashCode +
        (label == null ? 0 : label.hashCode) +
        title.hashCode +
        (pageId == null ? 0 : pageId.hashCode) +
        (mediaId == null ? 0 : mediaId.hashCode) +
        (mime == null ? 0 : mime.hashCode) +
        size.hashCode +
        (width == null ? 0 : width.hashCode) +
        (height == null ? 0 : height.hashCode) +
        (durationS == null ? 0 : durationS.hashCode) +
        hasCover.hashCode +
        hasPreview.hashCode +
        version.hashCode +
        visibility.hashCode +
        pinned.hashCode +
        (lastOpenedAt == null ? 0 : lastOpenedAt.hashCode) +
        canChange.hashCode +
        (publicUrl == null ? 0 : publicUrl.hashCode) +
        (deletedAt == null ? 0 : deletedAt.hashCode) +
        createdAt.hashCode +
        updatedAt.hashCode;

  factory Creation.fromJson(Map<String, dynamic> json) => _$CreationFromJson(json);

  Map<String, dynamic> toJson() => _$CreationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// Who can open it (D-281); a page's follows the page
enum CreationVisibilityEnum {
    /// Who can open it (D-281); a page's follows the page
@JsonValue(r'private')
private(r'private'),
    /// Who can open it (D-281); a page's follows the page
@JsonValue(r'workspace')
workspace(r'workspace'),
    /// Who can open it (D-281); a page's follows the page
@JsonValue(r'public')
public(r'public');

const CreationVisibilityEnum(this.value);

final String value;

@override
String toString() => value;
}


