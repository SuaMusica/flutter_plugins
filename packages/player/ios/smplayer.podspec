#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'smplayer'
  s.version          = '0.0.1'
  s.summary          = 'Desenvolvendo, conectando e amplificando o universo da música..'
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
  s.resources = ['Classes/**/*.{storyboard,xib,png}']
  s.dependency 'Flutter'
  s.dependency 'AFNetworking'
  s.dependency 'SDWebImage'
  s.dependency 'SDWebImageWebPCoder'
  s.platform = :ios, '9.0'
  s.ios.deployment_target = '9.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
