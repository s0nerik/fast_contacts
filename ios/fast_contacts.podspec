#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint fast_contacts.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'fast_contacts'
  s.version          = '0.0.1'
  s.summary          = 'Contacts plugin for Flutter'
  s.description      = <<-DESC
Contacts plugin for Flutter
                       DESC
  s.homepage         = 'https://pub.dev/packages/fast_contacts'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sasha Isaienko' => 'sonerik.dev@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'fast_contacts/Sources/fast_contacts/**/*.swift'
  s.dependency         'Flutter'
  s.platform         = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 and arm64 simulators are supported.
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64 arm64'
  }
  s.swift_version = '5.0'
end
