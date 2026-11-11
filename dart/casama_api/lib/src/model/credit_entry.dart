//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'credit_entry.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreditEntry {
  /// Returns a new [CreditEntry] instance.
  CreditEntry({

    required  this.delta,

    required  this.reason,

    required  this.note,

    required  this.balanceAfter,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'delta',
    required: true,
    includeIfNull: false,
  )


  final num delta;



  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final String reason;



  @JsonKey(
    
    name: r'note',
    required: true,
    includeIfNull: true,
  )


  final String? note;



  @JsonKey(
    
    name: r'balance_after',
    required: true,
    includeIfNull: false,
  )


  final num balanceAfter;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreditEntry &&
      other.delta == delta &&
      other.reason == reason &&
      other.note == note &&
      other.balanceAfter == balanceAfter &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        delta.hashCode +
        reason.hashCode +
        (note == null ? 0 : note.hashCode) +
        balanceAfter.hashCode +
        createdAt.hashCode;

  factory CreditEntry.fromJson(Map<String, dynamic> json) => _$CreditEntryFromJson(json);

  Map<String, dynamic> toJson() => _$CreditEntryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

