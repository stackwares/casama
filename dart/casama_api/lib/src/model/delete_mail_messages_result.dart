//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'delete_mail_messages_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeleteMailMessagesResult {
  /// Returns a new [DeleteMailMessagesResult] instance.
  DeleteMailMessagesResult({

    required  this.deleted,

    required  this.freed,
  });

  @JsonKey(
    
    name: r'deleted',
    required: true,
    includeIfNull: false,
  )


  final int deleted;



  @JsonKey(
    
    name: r'freed',
    required: true,
    includeIfNull: false,
  )


  final int freed;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeleteMailMessagesResult &&
      other.deleted == deleted &&
      other.freed == freed;

    @override
    int get hashCode =>
        deleted.hashCode +
        freed.hashCode;

  factory DeleteMailMessagesResult.fromJson(Map<String, dynamic> json) => _$DeleteMailMessagesResultFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteMailMessagesResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

