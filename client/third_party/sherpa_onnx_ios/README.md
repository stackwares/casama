# sherpa_onnx_ios (empty)

Stands in for `sherpa_onnx_ios` from pub.dev without the 25 MB `SherpaOnnxC.xcframework`. Wake word
(`lib/features/voice/wake_word.dart`) is off on iOS (`wakeWordSupported`), so nothing calls
sherpa-onnx there. If wake word ever comes to iOS, remove the `sherpa_onnx_ios` override from
`client/pubspec.yaml` and delete this folder.
