Pod::Spec.new do |s|
  s.name     = 'iCarousel'
  s.version  = '1.7.2'
  s.summary  = 'A simple, highly customisable, data-driven 3D carousel for iOS and Mac OS.'
  s.homepage = 'http://www.charcoaldesign.co.uk/source/cocoa#icarousel'
  s.author   = 'Nick Lockwood'
  s.source   = { :git => 'https://github.com/nicklockwood/iCarousel.git', :tag => '1.7.2' }

  s.description = 'iCarousel is a class designed to simplify the implementation of various ' \
                  'types of carousel (paged, scrolling views) on iPhone, iPad and Mac OS. ' \
                  'iCarousel implements a number of common effects such as cylindrical, flat ' \
                  'and "CoverFlow" style carousels, as well as providing hooks to implement ' \
                  'your own bespoke effects. Unlike many other "CoverFlow" libraries, ' \
                  'iCarousel can work with any kind of view, not just images, so it is ideal ' \
                  'for presenting paged data in a fluid and impressive way in your app. ' \
                  'It also makes it extremely easy to swap between different carousel effects ' \
                  'with minimal code changes.'
  s.source_files = 'iCarousel'
  s.frameworks   = 'QuartzCore'
  s.license      = { :type => 'zlib', :file => 'LICENCE.md' }
end
