Pod::Spec.new do |s|
  s.name         = "iCarousel"
  s.version      = "1.7.2"
  s.summary      = "A class designed to simplify the implementation of various types of carousel."
  s.homepage     = "https://github.com/nicklockwood/iCarousel"
  s.license      = { :type => 'MIT', :file => 'LICENCE.md' }
  s.author       = { "Nick Lockwood" => "support@charcoaldesign.co.uk" }  
  s.source       = { :git => "https://github.com/nicklockwood/iCarousel.git", :tag => "1.7.2" }
  s.requires_arc = true
  s.source_files = 'Classes', 'iCarousel/*.{h,m}'
  
  s.ios.deployment_target = '4.3'
  s.ios.frameworks = 'QuartzCore', 'CoreGraphics'

  s.osx.deployment_target = '10.7'
  s.ios.frameworks = 'QuartzCore'
end
