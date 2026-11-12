//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/computer_history_entry.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computer_history.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComputerHistory {
  /// Returns a new [ComputerHistory] instance.
  ComputerHistory({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<ComputerHistoryEntry> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ComputerHistory &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ComputerHistory.fromJson(Map<String, dynamic> json) => _$ComputerHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerHistoryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

