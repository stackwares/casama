//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'integration_test_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class IntegrationTestResult {
  /// Returns a new [IntegrationTestResult] instance.
  IntegrationTestResult({

    required  this.ok,

    required  this.tools,

     this.error,
  });

  @JsonKey(
    
    name: r'ok',
    required: true,
    includeIfNull: false,
  )


  final bool ok;



  @JsonKey(
    
    name: r'tools',
    required: true,
    includeIfNull: false,
  )


  final List<String> tools;



  @JsonKey(
    
    name: r'error',
    required: false,
    includeIfNull: false,
  )


  final String? error;





    @override
    bool operator ==(Object other) => identical(this, other) || other is IntegrationTestResult &&
      other.ok == ok &&
      other.tools == tools &&
      other.error == error;

    @override
    int get hashCode =>
        ok.hashCode +
        tools.hashCode +
        error.hashCode;

  factory IntegrationTestResult.fromJson(Map<String, dynamic> json) => _$IntegrationTestResultFromJson(json);

  Map<String, dynamic> toJson() => _$IntegrationTestResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

