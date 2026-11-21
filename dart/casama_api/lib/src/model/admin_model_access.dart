//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/admin_model_access_casama_models.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_model_access.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminModelAccess {
  /// Returns a new [AdminModelAccess] instance.
  AdminModelAccess({

    required  this.ownProviders,

    required  this.casamaModels,

    required  this.note,
  });

      /// Whether Cloud workspaces may use their own model keys and ChatGPT plans.
  @JsonKey(
    
    name: r'own_providers',
    required: true,
    includeIfNull: false,
  )


  final bool ownProviders;



  @JsonKey(
    
    name: r'casama_models',
    required: true,
    includeIfNull: false,
  )


  final AdminModelAccessCasamaModels casamaModels;



      /// Optional note shown on the blocked card when Casama's models are off.
  @JsonKey(
    
    name: r'note',
    required: true,
    includeIfNull: true,
  )


  final String? note;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminModelAccess &&
      other.ownProviders == ownProviders &&
      other.casamaModels == casamaModels &&
      other.note == note;

    @override
    int get hashCode =>
        ownProviders.hashCode +
        casamaModels.hashCode +
        (note == null ? 0 : note.hashCode);

  factory AdminModelAccess.fromJson(Map<String, dynamic> json) => _$AdminModelAccessFromJson(json);

  Map<String, dynamic> toJson() => _$AdminModelAccessToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

