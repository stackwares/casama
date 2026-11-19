//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'remote_app_config_crash_reporter.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RemoteAppConfigCrashReporter {
  /// Returns a new [RemoteAppConfigCrashReporter] instance.
  RemoteAppConfigCrashReporter({

     this.default_,

     this.ios,

     this.android,

     this.macos,

     this.windows,

     this.linux,

     this.web,
  });

      /// sentry, crashlytics, posthog or none
  @JsonKey(
    
    name: r'default',
    required: false,
    includeIfNull: false,
  )


  final String? default_;



      /// sentry, crashlytics, posthog or none
  @JsonKey(
    
    name: r'ios',
    required: false,
    includeIfNull: false,
  )


  final String? ios;



      /// sentry, crashlytics, posthog or none
  @JsonKey(
    
    name: r'android',
    required: false,
    includeIfNull: false,
  )


  final String? android;



      /// sentry, crashlytics, posthog or none
  @JsonKey(
    
    name: r'macos',
    required: false,
    includeIfNull: false,
  )


  final String? macos;



      /// sentry, crashlytics, posthog or none
  @JsonKey(
    
    name: r'windows',
    required: false,
    includeIfNull: false,
  )


  final String? windows;



      /// sentry, crashlytics, posthog or none
  @JsonKey(
    
    name: r'linux',
    required: false,
    includeIfNull: false,
  )


  final String? linux;



      /// sentry, crashlytics, posthog or none
  @JsonKey(
    
    name: r'web',
    required: false,
    includeIfNull: false,
  )


  final String? web;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RemoteAppConfigCrashReporter &&
      other.default_ == default_ &&
      other.ios == ios &&
      other.android == android &&
      other.macos == macos &&
      other.windows == windows &&
      other.linux == linux &&
      other.web == web;

    @override
    int get hashCode =>
        default_.hashCode +
        ios.hashCode +
        android.hashCode +
        macos.hashCode +
        windows.hashCode +
        linux.hashCode +
        web.hashCode;

  factory RemoteAppConfigCrashReporter.fromJson(Map<String, dynamic> json) => _$RemoteAppConfigCrashReporterFromJson(json);

  Map<String, dynamic> toJson() => _$RemoteAppConfigCrashReporterToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

