#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint snowplow.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'snowplow'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://www.suamusica.com.br'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sua Música' => 'contato@suamusica.com.br' }
  s.swift_version    = '5.0'
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{swift,h,m}'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'FMDB', '~> 2.7.2'
  s.dependency 'SnowplowTracker', '~> 2.0'
  # s.dependency 'UUIDNamespaces'
  s.platform = :ios, '9.0'


  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  # s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
