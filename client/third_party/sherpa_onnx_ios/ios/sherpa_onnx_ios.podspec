# Empty stand-in for sherpa_onnx_ios: no SherpaOnnxC framework (see ../README.md).
Pod::Spec.new do |s|
  s.name             = 'sherpa_onnx_ios'
  s.version          = '2.0.1'
  s.summary          = 'Empty iOS half of sherpa_onnx.'
  s.description      = 'Empty iOS half of sherpa_onnx; wake word does not run on iOS.'
  s.homepage         = 'https://github.com/k2-fsa/sherpa-onnx'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Casama' => 'hello@casama.ai' }
  s.source           = { :path => '.' }
  s.source_files     = 'sherpa_onnx_ios/Sources/sherpa_onnx_ios/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.swift_version = '5.0'
end
