//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ok.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Ok {
  /// Returns a new [Ok] instance.
  Ok({

    required  this.ok,
  });

  @JsonKey(
    
    name: r'ok',
    required: true,
    includeIfNull: false,
  )


  final bool ok;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Ok &&
      other.ok == ok;

    @override
    int get hashCode =>
        ok.hashCode;

  factory Ok.fromJson(Map<String, dynamic> json) => _$OkFromJson(json);

  Map<String, dynamic> toJson() => _$OkToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

