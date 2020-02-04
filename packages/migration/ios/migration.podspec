#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint migration.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'migration'
  s.version          = '0.0.1'
  s.summary          = 'Desenvolvendo, conectando e amplificando o universo da música..'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://www.suamusica.com.br'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sua Música' => 'contato@suamusica.com.br' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,m,swift,xcdatamodeld}'
  s.resources = 'Classes/**/*.xcdatamodeld'
  s.swift_version = '5.0'
  s.dependency 'Flutter'

  s.ios.deployment_target = '9.0'
end
