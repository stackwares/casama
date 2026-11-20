//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'refresh_live_card.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RefreshLiveCard {
  /// Returns a new [RefreshLiveCard] instance.
  RefreshLiveCard({

     this.view,

     this.force,
  });

  @JsonKey(
    
    name: r'view',
    required: false,
    includeIfNull: false,
  )


  final String? view;



  @JsonKey(
    
    name: r'force',
    required: false,
    includeIfNull: false,
  )


  final bool? force;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RefreshLiveCard &&
      other.view == view &&
      other.force == force;

    @override
    int get hashCode =>
        view.hashCode +
        force.hashCode;

  factory RefreshLiveCard.fromJson(Map<String, dynamic> json) => _$RefreshLiveCardFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshLiveCardToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

