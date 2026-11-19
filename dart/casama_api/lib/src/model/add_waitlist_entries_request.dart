//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'add_waitlist_entries_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddWaitlistEntriesRequest {
  /// Returns a new [AddWaitlistEntriesRequest] instance.
  AddWaitlistEntriesRequest({

    required  this.emails,

     this.notify,
  });

  @JsonKey(
    
    name: r'emails',
    required: true,
    includeIfNull: false,
  )


  final List<String> emails;



  @JsonKey(
    
    name: r'notify',
    required: false,
    includeIfNull: false,
  )


  final bool? notify;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AddWaitlistEntriesRequest &&
      other.emails == emails &&
      other.notify == notify;

    @override
    int get hashCode =>
        emails.hashCode +
        notify.hashCode;

  factory AddWaitlistEntriesRequest.fromJson(Map<String, dynamic> json) => _$AddWaitlistEntriesRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AddWaitlistEntriesRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

