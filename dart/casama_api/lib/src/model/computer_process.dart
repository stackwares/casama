//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computer_process.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComputerProcess {
  /// Returns a new [ComputerProcess] instance.
  ComputerProcess({

    required  this.pid,

    required  this.name,

    required  this.command,

    required  this.cpuPercent,

    required  this.memoryBytes,

    required  this.elapsedSeconds,

    required  this.system,
  });

  @JsonKey(
    
    name: r'pid',
    required: true,
    includeIfNull: false,
  )


  final int pid;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'command',
    required: true,
    includeIfNull: false,
  )


  final String command;



  @JsonKey(
    
    name: r'cpu_percent',
    required: true,
    includeIfNull: false,
  )


  final num cpuPercent;



  @JsonKey(
    
    name: r'memory_bytes',
    required: true,
    includeIfNull: false,
  )


  final int memoryBytes;



  @JsonKey(
    
    name: r'elapsed_seconds',
    required: true,
    includeIfNull: false,
  )


  final int elapsedSeconds;



      /// Part of the computer itself; can't be stopped
  @JsonKey(
    
    name: r'system',
    required: true,
    includeIfNull: false,
  )


  final bool system;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ComputerProcess &&
      other.pid == pid &&
      other.name == name &&
      other.command == command &&
      other.cpuPercent == cpuPercent &&
      other.memoryBytes == memoryBytes &&
      other.elapsedSeconds == elapsedSeconds &&
      other.system == system;

    @override
    int get hashCode =>
        pid.hashCode +
        name.hashCode +
        command.hashCode +
        cpuPercent.hashCode +
        memoryBytes.hashCode +
        elapsedSeconds.hashCode +
        system.hashCode;

  factory ComputerProcess.fromJson(Map<String, dynamic> json) => _$ComputerProcessFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerProcessToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

