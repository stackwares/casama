//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'block_mail_sender_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BlockMailSenderRequest {
  /// Returns a new [BlockMailSenderRequest] instance.
  BlockMailSenderRequest({

    required  this.sender,
  });

  @JsonKey(
    
    name: r'sender',
    required: true,
    includeIfNull: false,
  )


  final String sender;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BlockMailSenderRequest &&
      other.sender == sender;

    @override
    int get hashCode =>
        sender.hashCode;

  factory BlockMailSenderRequest.fromJson(Map<String, dynamic> json) => _$BlockMailSenderRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BlockMailSenderRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

