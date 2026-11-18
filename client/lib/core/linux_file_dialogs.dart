import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_picker_linux/file_picker_linux.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/foundation.dart';

/// Linux: file_picker opens its dialogs only through the desktop portal
/// (org.freedesktop.portal.Desktop). Without one (i3, Sway and other setups without
/// xdg-desktop-portal, or a portal that failed to start) every pick threw and the click did nothing.
/// Installed at startup, this keeps the portal and falls back to GTK's own dialog
/// (file_selector) when the portal isn't there. Every `FilePicker` call goes through it.
void useLinuxFileDialogFallback() {
  if (kIsWeb || !Platform.isLinux) return;
  final portal = FilePickerPlatform.instance;
  if (portal is LinuxFileDialogs) return;
  FilePickerPlatform.instance = LinuxFileDialogs(portal, FileSelectorPlatform.instance);
}

@visibleForTesting
class LinuxFileDialogs extends FilePickerPlatform {
  LinuxFileDialogs(this.portal, this.gtk);
  final FilePickerPlatform portal;
  final FileSelectorPlatform gtk;

  /// Set once the portal fails, so later dialogs open straight away.
  bool _noPortal = false;

  Future<T> _either<T>(Future<T> Function() viaPortal, Future<T> Function() viaGtk) async {
    if (!_noPortal) {
      try {
        return await viaPortal();
      } catch (e) {
        debugPrint('file dialog: no desktop portal ($e); using the GTK dialog');
        _noPortal = true;
      }
    }
    return viaGtk();
  }

  static List<XTypeGroup>? _groups(FileType type, List<String>? extensions) => switch (type) {
        FileType.custom when extensions != null && extensions.isNotEmpty => [XTypeGroup(label: 'Files', extensions: extensions)],
        FileType.image => const [XTypeGroup(label: 'Images', mimeTypes: ['image/*'])],
        FileType.video => const [XTypeGroup(label: 'Videos', mimeTypes: ['video/*'])],
        FileType.audio => const [XTypeGroup(label: 'Audio', mimeTypes: ['audio/*'])],
        FileType.media => const [XTypeGroup(label: 'Images and videos', mimeTypes: ['image/*', 'video/*'])],
        _ => null,
      };

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
  }) =>
      _either(
        () => portal.pickFiles(
          dialogTitle: dialogTitle,
          initialDirectory: initialDirectory,
          type: type,
          allowedExtensions: allowedExtensions,
          onFileLoading: onFileLoading,
          compressionQuality: compressionQuality,
          linuxOptions: linuxOptions,
        ),
        () async => [
          for (final f in await gtk.openFiles(acceptedTypeGroups: _groups(type, allowedExtensions), initialDirectory: initialDirectory))
            LinuxPlatformFile.fromPath(f.path),
        ],
      );

  @override
  Future<PlatformFile?> pickFile({
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
  }) =>
      _either(
        () => portal.pickFile(
          dialogTitle: dialogTitle,
          initialDirectory: initialDirectory,
          type: type,
          allowedExtensions: allowedExtensions,
          onFileLoading: onFileLoading,
          compressionQuality: compressionQuality,
          linuxOptions: linuxOptions,
        ),
        () async {
          final f = await gtk.openFile(acceptedTypeGroups: _groups(type, allowedExtensions), initialDirectory: initialDirectory);
          return f == null ? null : LinuxPlatformFile.fromPath(f.path);
        },
      );

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) =>
      _either(
        () => portal.getDirectoryPath(dialogTitle: dialogTitle, initialDirectory: initialDirectory, linuxOptions: linuxOptions),
        () => gtk.getDirectoryPathWithOptions(FileDialogOptions(initialDirectory: initialDirectory, canCreateDirectories: true)),
      );

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) =>
      _either(
        () => portal.saveFile(
          fileName: fileName,
          bytes: bytes,
          mimeType: mimeType,
          dialogTitle: dialogTitle,
          initialDirectory: initialDirectory,
          onFileSaving: onFileSaving,
          linuxOptions: linuxOptions,
        ),
        () async {
          final at = await gtk.getSaveLocation(
            options: SaveDialogOptions(suggestedName: fileName, initialDirectory: initialDirectory, canCreateDirectories: true),
          );
          if (at == null) return null;
          await File(at.path).writeAsBytes(bytes);
          return Uri.file(at.path);
        },
      );

  @override
  Future<List<String>> pickFileAndDirectoryPaths({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) =>
      portal.pickFileAndDirectoryPaths(
        dialogTitle: dialogTitle,
        initialDirectory: initialDirectory,
        type: type,
        allowedExtensions: allowedExtensions,
      );

  @override
  Future<void> clearTemporaryFiles() => portal.clearTemporaryFiles();
}
