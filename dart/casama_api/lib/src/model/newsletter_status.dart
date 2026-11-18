//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'newsletter_status.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NewsletterStatus {
  /// Returns a new [NewsletterStatus] instance.
  NewsletterStatus({

    required  this.available,

    required  this.subscribed,

    required  this.asked,
  });

  @JsonKey(
    
    name: r'available',
    required: true,
    includeIfNull: false,
  )


  final bool available;



  @JsonKey(
    
    name: r'subscribed',
    required: true,
    includeIfNull: false,
  )


  final bool subscribed;



  @JsonKey(
    
    name: r'asked',
    required: true,
    includeIfNull: false,
  )


  final bool asked;





    @override
    bool operator ==(Object other) => identical(this, other) || other is NewsletterStatus &&
      other.available == available &&
      other.subscribed == subscribed &&
      other.asked == asked;

    @override
    int get hashCode =>
        available.hashCode +
        subscribed.hashCode +
        asked.hashCode;

  factory NewsletterStatus.fromJson(Map<String, dynamic> json) => _$NewsletterStatusFromJson(json);

  Map<String, dynamic> toJson() => _$NewsletterStatusToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

