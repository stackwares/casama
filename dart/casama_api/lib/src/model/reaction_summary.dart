//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reaction_summary.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReactionSummary {
  /// Returns a new [ReactionSummary] instance.
  ReactionSummary({

    required  this.emoji,

    required  this.count,

    required  this.mine,

    required  this.users,

    required  this.bots,
  });

  @JsonKey(
    
    name: r'emoji',
    required: true,
    includeIfNull: false,
  )


  final String emoji;



  @JsonKey(
    
    name: r'count',
    required: true,
    includeIfNull: false,
  )


  final int count;



      /// You reacted with this emoji
  @JsonKey(
    
    name: r'mine',
    required: true,
    includeIfNull: false,
  )


  final bool mine;



      /// People who reacted with it (the first 20)
  @JsonKey(
    
    name: r'users',
    required: true,
    includeIfNull: false,
  )


  final List<String> users;



      /// Bots that reacted with it
  @JsonKey(
    
    name: r'bots',
    required: true,
    includeIfNull: false,
  )


  final List<String> bots;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReactionSummary &&
      other.emoji == emoji &&
      other.count == count &&
      other.mine == mine &&
      other.users == users &&
      other.bots == bots;

    @override
    int get hashCode =>
        emoji.hashCode +
        count.hashCode +
        mine.hashCode +
        users.hashCode +
        bots.hashCode;

  factory ReactionSummary.fromJson(Map<String, dynamic> json) => _$ReactionSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$ReactionSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

