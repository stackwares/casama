//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'deleted_conversations.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeletedConversations {
  /// Returns a new [DeletedConversations] instance.
  DeletedConversations({

    required  this.deleted,

    required  this.skipped,
  });

      /// How many conversations were deleted
  @JsonKey(
    
    name: r'deleted',
    required: true,
    includeIfNull: false,
  )


  final int deleted;



      /// Left alone because the bot is still working in them
  @JsonKey(
    
    name: r'skipped',
    required: true,
    includeIfNull: false,
  )


  final int skipped;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeletedConversations &&
      other.deleted == deleted &&
      other.skipped == skipped;

    @override
    int get hashCode =>
        deleted.hashCode +
        skipped.hashCode;

  factory DeletedConversations.fromJson(Map<String, dynamic> json) => _$DeletedConversationsFromJson(json);

  Map<String, dynamic> toJson() => _$DeletedConversationsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

