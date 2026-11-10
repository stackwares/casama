// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_proposal_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SkillProposalListCWProxy {
  SkillProposalList items(List<SkillProposal> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SkillProposalList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SkillProposalList(...).copyWith(id: 12, name: "My name")
  /// ```
  SkillProposalList call({List<SkillProposal> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSkillProposalList.copyWith(...)` or call `instanceOfSkillProposalList.copyWith.fieldName(value)` for a single field.
class _$SkillProposalListCWProxyImpl implements _$SkillProposalListCWProxy {
  const _$SkillProposalListCWProxyImpl(this._value);

  final SkillProposalList _value;

  @override
  SkillProposalList items(List<SkillProposal> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SkillProposalList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SkillProposalList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SkillProposalList call({Object? items = const $CopyWithPlaceholder()}) {
    return SkillProposalList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<SkillProposal>,
    );
  }
}

extension $SkillProposalListCopyWith on SkillProposalList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSkillProposalList.copyWith(...)` or `instanceOfSkillProposalList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SkillProposalListCWProxy get copyWith =>
      _$SkillProposalListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkillProposalList _$SkillProposalListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SkillProposalList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = SkillProposalList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => SkillProposal.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SkillProposalListToJson(SkillProposalList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
