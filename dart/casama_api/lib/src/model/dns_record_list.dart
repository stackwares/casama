//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/dns_record_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dns_record_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DnsRecordList {
  /// Returns a new [DnsRecordList] instance.
  DnsRecordList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<DnsRecordItem> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DnsRecordList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory DnsRecordList.fromJson(Map<String, dynamic> json) => _$DnsRecordListFromJson(json);

  Map<String, dynamic> toJson() => _$DnsRecordListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

