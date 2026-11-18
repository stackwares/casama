// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_lists_starters.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryListsStartersCWProxy {
  GalleryListsStarters library_(List<LibraryStarter>? library_);

  GalleryListsStarters tasks(List<TextStarter>? tasks);

  GalleryListsStarters support(List<TextStarter>? support);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryListsStarters(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryListsStarters(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryListsStarters call({
    List<LibraryStarter>? library_,
    List<TextStarter>? tasks,
    List<TextStarter>? support,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryListsStarters.copyWith(...)` or call `instanceOfGalleryListsStarters.copyWith.fieldName(value)` for a single field.
class _$GalleryListsStartersCWProxyImpl
    implements _$GalleryListsStartersCWProxy {
  const _$GalleryListsStartersCWProxyImpl(this._value);

  final GalleryListsStarters _value;

  @override
  GalleryListsStarters library_(List<LibraryStarter>? library_) =>
      call(library_: library_);

  @override
  GalleryListsStarters tasks(List<TextStarter>? tasks) => call(tasks: tasks);

  @override
  GalleryListsStarters support(List<TextStarter>? support) =>
      call(support: support);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryListsStarters(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryListsStarters(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryListsStarters call({
    Object? library_ = const $CopyWithPlaceholder(),
    Object? tasks = const $CopyWithPlaceholder(),
    Object? support = const $CopyWithPlaceholder(),
  }) {
    return GalleryListsStarters(
      library_: library_ == const $CopyWithPlaceholder()
          ? _value.library_
          // ignore: cast_nullable_to_non_nullable
          : library_ as List<LibraryStarter>?,
      tasks: tasks == const $CopyWithPlaceholder()
          ? _value.tasks
          // ignore: cast_nullable_to_non_nullable
          : tasks as List<TextStarter>?,
      support: support == const $CopyWithPlaceholder()
          ? _value.support
          // ignore: cast_nullable_to_non_nullable
          : support as List<TextStarter>?,
    );
  }
}

extension $GalleryListsStartersCopyWith on GalleryListsStarters {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryListsStarters.copyWith(...)` or `instanceOfGalleryListsStarters.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryListsStartersCWProxy get copyWith =>
      _$GalleryListsStartersCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryListsStarters _$GalleryListsStartersFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GalleryListsStarters', json, ($checkedConvert) {
  final val = GalleryListsStarters(
    library_: $checkedConvert(
      'library',
      (v) => (v as List<dynamic>?)
          ?.map((e) => LibraryStarter.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    tasks: $checkedConvert(
      'tasks',
      (v) => (v as List<dynamic>?)
          ?.map((e) => TextStarter.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    support: $checkedConvert(
      'support',
      (v) => (v as List<dynamic>?)
          ?.map((e) => TextStarter.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'library_': 'library'});

Map<String, dynamic> _$GalleryListsStartersToJson(
  GalleryListsStarters instance,
) => <String, dynamic>{
  'library': ?instance.library_?.map((e) => e.toJson()).toList(),
  'tasks': ?instance.tasks?.map((e) => e.toJson()).toList(),
  'support': ?instance.support?.map((e) => e.toJson()).toList(),
};
