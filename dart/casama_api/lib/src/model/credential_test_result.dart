//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'credential_test_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CredentialTestResult {
  /// Returns a new [CredentialTestResult] instance.
  CredentialTestResult({

    required  this.ok,

    required  this.model,

    required  this.latencyMs,

     this.error,
  });

  @JsonKey(
    
    name: r'ok',
    required: true,
    includeIfNull: false,
  )


  final bool ok;



  @JsonKey(
    
    name: r'model',
    required: true,
    includeIfNull: false,
  )


  final String model;



  @JsonKey(
    
    name: r'latency_ms',
    required: true,
    includeIfNull: false,
  )


  final int latencyMs;



  @JsonKey(
    
    name: r'error',
    required: false,
    includeIfNull: false,
  )


  final String? error;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CredentialTestResult &&
      other.ok == ok &&
      other.model == model &&
      other.latencyMs == latencyMs &&
      other.error == error;

    @override
    int get hashCode =>
        ok.hashCode +
        model.hashCode +
        latencyMs.hashCode +
        error.hashCode;

  factory CredentialTestResult.fromJson(Map<String, dynamic> json) => _$CredentialTestResultFromJson(json);

  Map<String, dynamic> toJson() => _$CredentialTestResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

