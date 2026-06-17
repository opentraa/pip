#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint pip.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'pip'
  s.version          = '0.0.4'
  s.summary          = 'A plugin for Picture in Picture.'
  s.description      = <<-DESC
A plugin for Picture in Picture.
                       DESC
  s.homepage         = 'https://github.com/opentraa/pip'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sylar' => 'peilinok@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'pip/Sources/pip/**/*.{h,m}'
  s.public_header_files = 'pip/Sources/pip/include/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  s.resource_bundles = {'flutter_pip_privacy' => ['pip/Sources/pip/PrivacyInfo.xcprivacy']}
end
