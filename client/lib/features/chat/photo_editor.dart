import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

/// Crop, rotate, draw on, write on, or adjust a photo before it goes into a chat. Returns the
/// edited picture as a JPEG, or null if the person backed out. Native Flutter widgets, no web
/// view, on every platform.
Future<Uint8List?> editPhoto(BuildContext context, Uint8List bytes) {
  return Navigator.of(context, rootNavigator: true).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => _PhotoEditor(bytes: bytes),
    ),
  );
}

class _PhotoEditor extends StatefulWidget {
  const _PhotoEditor({required this.bytes});
  final Uint8List bytes;

  @override
  State<_PhotoEditor> createState() => _PhotoEditorState();
}

class _PhotoEditorState extends State<_PhotoEditor> {
  Uint8List? _result;

  @override
  Widget build(BuildContext context) {
    return ProImageEditor.memory(
      widget.bytes,
      configs: const ProImageEditorConfigs(
        // The basics people expect from a chat app; no stickers, emoji or blur brushes.
        mainEditor: MainEditorConfigs(
          tools: [
            SubEditorMode.cropRotate,
            SubEditorMode.paint,
            SubEditorMode.text,
            SubEditorMode.tune,
            SubEditorMode.filter,
          ],
        ),
        // Same size limit as a photo picked without editing (see chat_screen's picker), so an
        // edit never makes the upload bigger.
        imageGeneration: ImageGenerationConfigs(
          outputFormat: OutputFormat.jpg,
          jpegQuality: 85,
          maxOutputSize: Size(2048, 2048),
        ),
      ),
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: (bytes) async => _result = bytes,
        onCloseEditor: (_) {
          if (mounted) Navigator.of(context).pop(_result);
        },
      ),
    );
  }
}
