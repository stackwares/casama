//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'delete_mail_messages_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeleteMailMessagesRequest {
  /// Returns a new [DeleteMailMessagesRequest] instance.
  DeleteMailMessagesRequest({

     this.ids,

     this.before,
  });

  @JsonKey(
    
    name: r'ids',
    required: false,
    includeIfNull: false,
  )


  final List<String>? ids;



  @JsonKey(
    
    name: r'before',
    required: false,
    includeIfNull: false,
  )


  final DateTime? before;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeleteMailMessagesRequest &&
      other.ids == ids &&
      other.before == before;

    @override
    int get hashCode =>
        ids.hashCode +
        before.hashCode;

  factory DeleteMailMessagesRequest.fromJson(Map<String, dynamic> json) => _$DeleteMailMessagesRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteMailMessagesRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

