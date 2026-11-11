//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'checkpoint.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Checkpoint {
  /// Returns a new [Checkpoint] instance.
  Checkpoint({

    required  this.id,

    required  this.computerId,

    required  this.runId,

    required  this.label,

    required  this.size,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'computer_id',
    required: true,
    includeIfNull: false,
  )


  final String computerId;



  @JsonKey(
    
    name: r'run_id',
    required: true,
    includeIfNull: true,
  )


  final String? runId;



  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  )


  final String label;



  @JsonKey(
    
    name: r'size',
    required: true,
    includeIfNull: false,
  )


  final int size;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Checkpoint &&
      other.id == id &&
      other.computerId == computerId &&
      other.runId == runId &&
      other.label == label &&
      other.size == size &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        computerId.hashCode +
        (runId == null ? 0 : runId.hashCode) +
        label.hashCode +
        size.hashCode +
        createdAt.hashCode;

  factory Checkpoint.fromJson(Map<String, dynamic> json) => _$CheckpointFromJson(json);

  Map<String, dynamic> toJson() => _$CheckpointToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

