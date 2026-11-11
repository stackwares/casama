//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_gpt_sign_in_complete_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChatGptSignInCompleteRequest {
  /// Returns a new [ChatGptSignInCompleteRequest] instance.
  ChatGptSignInCompleteRequest({

    required  this.state,

     this.code,

     this.clientId,

     this.error,

     this.errorDescription,
  });

  @JsonKey(
    
    name: r'state',
    required: true,
    includeIfNull: false,
  )


  final String state;



  @JsonKey(
    
    name: r'code',
    required: false,
    includeIfNull: false,
  )


  final String? code;



      /// The issued client id from the callback (first sign-in)
  @JsonKey(
    
    name: r'client_id',
    required: false,
    includeIfNull: false,
  )


  final String? clientId;



  @JsonKey(
    
    name: r'error',
    required: false,
    includeIfNull: false,
  )


  final String? error;



  @JsonKey(
    
    name: r'error_description',
    required: false,
    includeIfNull: false,
  )


  final String? errorDescription;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ChatGptSignInCompleteRequest &&
      other.state == state &&
      other.code == code &&
      other.clientId == clientId &&
      other.error == error &&
      other.errorDescription == errorDescription;

    @override
    int get hashCode =>
        state.hashCode +
        code.hashCode +
        clientId.hashCode +
        error.hashCode +
        errorDescription.hashCode;

  factory ChatGptSignInCompleteRequest.fromJson(Map<String, dynamic> json) => _$ChatGptSignInCompleteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ChatGptSignInCompleteRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

