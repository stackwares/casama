//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'waitlist_changed.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WaitlistChanged {
  /// Returns a new [WaitlistChanged] instance.
  WaitlistChanged({

    required  this.count,

     this.skipped,
  });

  @JsonKey(
    
    name: r'count',
    required: true,
    includeIfNull: false,
  )


  final int count;



  @JsonKey(
    
    name: r'skipped',
    required: false,
    includeIfNull: false,
  )


  final List<String>? skipped;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WaitlistChanged &&
      other.count == count &&
      other.skipped == skipped;

    @override
    int get hashCode =>
        count.hashCode +
        skipped.hashCode;

  factory WaitlistChanged.fromJson(Map<String, dynamic> json) => _$WaitlistChangedFromJson(json);

  Map<String, dynamic> toJson() => _$WaitlistChangedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

