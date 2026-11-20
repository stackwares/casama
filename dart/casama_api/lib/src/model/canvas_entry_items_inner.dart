//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'canvas_entry_items_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CanvasEntryItemsInner {
  /// Returns a new [CanvasEntryItemsInner] instance.
  CanvasEntryItemsInner({

    required  this.text,

    required  this.done,
  });

  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;



  @JsonKey(
    
    name: r'done',
    required: true,
    includeIfNull: false,
  )


  final bool done;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CanvasEntryItemsInner &&
      other.text == text &&
      other.done == done;

    @override
    int get hashCode =>
        text.hashCode +
        done.hashCode;

  factory CanvasEntryItemsInner.fromJson(Map<String, dynamic> json) => _$CanvasEntryItemsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasEntryItemsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

