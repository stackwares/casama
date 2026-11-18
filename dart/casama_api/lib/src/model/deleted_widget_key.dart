//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'deleted_widget_key.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeletedWidgetKey {
  /// Returns a new [DeletedWidgetKey] instance.
  DeletedWidgetKey({

    required  this.deleted,
  });

  @JsonKey(
    
    name: r'deleted',
    required: true,
    includeIfNull: false,
  )


  final String deleted;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeletedWidgetKey &&
      other.deleted == deleted;

    @override
    int get hashCode =>
        deleted.hashCode;

  factory DeletedWidgetKey.fromJson(Map<String, dynamic> json) => _$DeletedWidgetKeyFromJson(json);

  Map<String, dynamic> toJson() => _$DeletedWidgetKeyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

