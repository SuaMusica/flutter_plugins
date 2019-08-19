#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'suamusica_player'
  s.version          = '0.0.1'
  s.summary          = 'Desenvolvendo, conectando e amplificando o universo da música..'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://www.suamusica.com.br'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sua Música' => 'contato@suamusica.com.br' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '8.0'
end

