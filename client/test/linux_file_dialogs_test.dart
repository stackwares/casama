import 'dart:io';

import 'package:casama/core/linux_file_dialogs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

/// The portal picker: answers, or fails like file_picker_linux without org.freedesktop.portal.Desktop.
final class _Portal extends FilePickerPlatform {
  _Portal({this.available = true});
  final bool available;
  int calls = 0;

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    calls++;
    if (!available) throw Exception('org.freedesktop.DBus.Error.ServiceUnknown');
    return const [];
  }
}

class _Gtk extends FileSelectorPlatform {
  _Gtk(this.paths);
  final List<String> paths;
  List<XTypeGroup>? groups;

  @override
  Future<List<XFile>> openFiles({List<XTypeGroup>? acceptedTypeGroups, String? initialDirectory, String? confirmButtonText}) async {
    groups = acceptedTypeGroups;
    return [for (final p in paths) XFile(p)];
  }
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('casama-files'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('with a portal, its dialog opens and GTK is never asked', () async {
    final gtk = _Gtk(['/never']);
    final picked = await LinuxFileDialogs(_Portal(), gtk).pickFiles();
    expect(picked, isEmpty);
    expect(gtk.groups, isNull);
  });

  test('without a portal, GTK picks the files, with their bytes and the allowed types', () async {
    final note = File('${dir.path}/note.txt')..writeAsStringSync('hello');
    final portal = _Portal(available: false);
    final gtk = _Gtk([note.path]);
    final dialogs = LinuxFileDialogs(portal, gtk);

    final picked = await dialogs.pickFiles(type: FileType.custom, allowedExtensions: const ['txt', 'md']);
    expect(picked.single.name, 'note.txt');
    expect(String.fromCharCodes(await picked.single.readAsBytes()), 'hello');
    expect(gtk.groups!.single.extensions, ['txt', 'md']);

    // The portal isn't asked again once it's known to be missing.
    await dialogs.pickFiles();
    expect(portal.calls, 1);
  });
}
