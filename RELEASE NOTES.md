Verson 1.8 beta

- iCarousel now requires ARC
- iCarousel now requires 64-bit processors on Mac OS
- Added pagingEnabled property to force carousel to only move a single index per swipe
- Fixed bug which occasionally caused carousel item views to pop-in from right
- Removed all deprecated methods and APIs
- Added iCarouselOptionFadeMinAlpha option for setting minimum fade
- Setting scrollOffset now lets you exactly mirror behaviour from one carousel to another
- Fixed bug where item indexes were selected incorrectly when tapping views in vertical mode
- Perspective and viewpointOffset properties can now be animated

Version 1.7.6

- Fixed animation timer bug when using ARC

Version 1.7.5

- Fixed an issue with latest llvm compiler
- Fixed confict between iCarousel animation and UIScrollView scrolling

Version 1.7.4

- Fixed deprecation warnings when using Xcode 4.6
- Fixed wide items in a vertical carousel getting incorrect hitboxes
- Added podspec file

Version 1.7.3

- Moved ARCHelper macros into .m file to avoid affecting other classes

Version 1.7.2

- Core animation is no longer disabled when calling delegate methods.
- Fixed a potential divide-by-zero error when scrolling
- Removed useDisplayLink option as the performance benefits are unclear
- Added dragging, scrolling and decelerating properties (readonly)
- iCarouselWrap property is now refreshed after inserting/deleting items
- Added Autoscrolling Example
- Added Fading Demo example

Version 1.7.1

- Fixed issue where reloading carousel with fewer items could sometimes crash
- Fixed issue where scrollToItemAtIndex:duration: method would sometimes scroll to the wrong index

Version 1.7

- Renamed iCarouselTransformOption... values to "iCarouselOption", and extended the list of available options
- Simplified carousel interface by deprecating a number of delegate methods in favour of the simpler iCarouselOption API
- numberOfVisibleItems is now calculated automatically
- Added Dynamic Downloads example using AsyncImageView
- Added Dynamic Effects examples using FXImageView
- Item view interaction area is now more precisely set on iOS
- Fixed backface interaction issue for iCarouselTypeInvertedCylinder
- It is now much simpler to implement alpha fading logic based on item offset 
- Now supports item click events and centering on Mac OS (buttons and controls within item views still won't work correctly receive clicks however).
- Added scrollToOffset: and scrollByOffset: methods
- Disabled broken scrollwheel support for carousel on Mac OS
- currentItemIndex property is now writable
- scrollOffset property is now writable
- Fixed bug with scrollByNumberOfItems where duration is 0
- Switched CADisplayLink to use NSDefaultRunLoopMode, which is less likely to interfere with UIScrollViews, etc
- Added Storyboard example

Version 1.6.3

- Added offsetForItemAtIndex: method
- Fixed bug in reloadItemViewAtIndex:animated: method
- Fixed Mac OS scrolling glitch when using numberOfVisibleViews
- iCarousel now respects the layer.doubleSided property of item views
- Added Basic and Multiple Carousels example projects

Version 1.6.2

- Fixed long-standing viewpointOffset bug
- Fixed potential bug around not setting default carousel type
- LLVM GCC compiler is no longer supported, Now requires Apple LLVM compiler
- Upgraded to latest ARC Helper code

Version 1.6.1

- Added automatic support for ARC compile targets
- Now compiles correctly again under LLVM GCC 4.2
- Vertical Time Machine carousel is now right-way-up on Mac OS
- Added Inverted Time Machine carousel type
- Added dynamic reflections example
- Fixed crashing bug in examples on iPad
- Carousels now behave better with 1 or 2 items

Version 1.6

- Added support for item view recycling
- Carousels can now be either horizontal or vertical
- Added Wheel and Time Machine carousel types
- Added new iCarouselTransformOption system for tweaking the standard carousel transforms without having to provide a completely bespoke implementation
- Added ignorePerpendicularSwipes property
- Fixed issue with scrolling immediately after reloading
- Added useDisplayLink toggle to manually force use of NSTimer
- Added support for the Chameleon iOS-to-Mac porting library
- Removed the deprecated visibleViews property
- Added carousel:alphaForViewAtItemWithOffset: delegate method for controlling view opacity
- Added indexOfItemViewOrSubview: method to simplify handling of controls within  carousel item views
- Deprecated/renamed some dataSource and delegate methods - check your projects for compatibility
- Expanded examples and tests

Version 1.5.8

- Fixed bug in previous UITableCell fix
- No longer gets stuck at a negative offset when inserting items into an empty carousel
- Example app no longer crashes when inserting item into empty carousel
- Better behaviour when reloading carousel

Version 1.5.7

- Fixed ARC compatibility issues with sorting logic
- UISwitches, UISliders and UITableCells now work correctly with item views
- Fixed bug in carousel:shouldSelectItemAtIndex: delegate logic

Version 1.5.6

- Added reloadItemAtIndex:animated: method.
- Fixed some issues when setting offset or carousel bounds on the fly.
- Less aggressive use of [CATransaction setDisableActions:YES] means more properties of carousel are now animatable (including setting the type).
- Fixed NaN bug when displaying an empty carousel
- Fixed glitch when programatically scrolling CoverFlow2-type carousel.
- Cylinder and rotary carousel are now sized to fit visible number of items.

Version 1.5.5

- Deprecated visibleViews property
- Added visibleItemViews property, which is an array
- Added indexesForVisibleItems property
- Added itemViewAtIndex: method
- Added currentItemView property
- Added indexOfItemView: method
- Fixed glitch when unwrapped CoverFlow2-type carousels reach the far right
- Scroll animation events are now called immediately after scrolling ends if the carousel does not need to scroll a significant distance.
- Fixed jerky bounce animation on CoverFlow2-type carousels when stopAtItemBoundary is set to NO.

Version 1.5.4

- Fixed a bug where insertItemAtIndex method would not allow items to be inserted at the rightmost end of the carousel.

Version 1.5.3

- Fixed a bug on wrapped carousels when the total number of carousel items exceeds the number of visible items.
- Changed numberOfVisibleItems property to be a dataSource method, removing the arbitrary default limit of 21.
- Fixed a flickering issue on CoverFlow2 carousel type.
- Fixed bug on Mac where clicking would spin the carousel a random distance.
- scrollSpeed is now a read/write property, and only affects speed when carousel is flicked.
- Removed `carouselScrollSpeed` delegate method and replaced it with new `offsetMultiplier` property and `carouselOffsetMultiplier` delegate method to control the offset when dragging.
- scrollOffset property is now public (readonly).
- Floating point arguments and properties are now CGFloats instead of floats.

Version 1.5.2

- Added bounceDistance property for finer control over bounce behaviour.
- Added `carousel:shouldSelectItemAtIndex:` delegate method to allow carousel to selectively ignore taps.
- Added `stopAtItemBoundary` and `scrollToItemBoundary` properties.
- Fixed issue with carousel wrapping unexpectedly when wrapping and bouncing are disabled.
- Fixed issue with rightmost visible view sometimes not loading.
- Improved the `iCarouselTypeCoverFlow2` implementation.
- Tweaked acceleration parameters for smoother scrolling behaviour.
- Improved loading sequence to reduce repeated calls to dataSource methods during startup.
- Added No-nib example for iPhone to demonstrate setting up the carousel in code.

Version 1.5.1

- Fixed issue with item button events being blocked by gesture recogniser.
- Tweaked bounce and acceleration parameters for smoother scrolling.
- Made `toggle` property public (used to implement CoverFlow2 carousel style).

Version 1.5

- Added a new carousel type, iCarouselTypeCoverflow2, which more closely matches the appearance of the standard Apple CoverFlow implementation.
- iCarousel now always stops exactly on an item boundary when decelerating, instead of over or under-shooting and scrolling to the correct position.
- Added carouselScrollSpeed delegate method and increased default scrolling speed for CoverFlow carousel types.
- Animation now uses CADisplayLink on iOS for better performance.
- Animation is now paused when carousel is not moving.
- Reduced default deceleration rate so carousel can be 'flicked' further.
- Added insert/remove carousel item support for Mac OS.

Version 1.4

- Added a new dynamic loading system to load and release views as needed. The carousel can now contain hundreds of thousands of items but only display a subset of them.
- Added numberOfVisibleItems property to control the number of views to be loaded concurrently.
- Added visibleViews property, containing a set of all visible item views.
- Removed the itemViews and placeholderViews properties, as these no longer work with the new loading system.

Version 1.3.4

- Changed order of execution for when carouselDidEndScrollingAnimation is called to prevent animation glitches when making changes to carousel in the callback.
- Fixed glitch where didSelectItemAtIndex method would never fire for the currently centered view.

Version 1.3.3

- Added several additional delegate methods for tracking when the carousel scrolls and decelerates.
- Fixed some glitches when using the scrollwheel/trackpad on a Mac.

Version 1.3.2

- Fixed additional scrolling bug introduced by 1.3.1 fix.
- Improved deceleration logic on non-wrapped carousels.

Version 1.3.1

- Fixed scrolling bug on wrapped carousels when scrolling from item at index zero back to the last item.

Version 1.3

- Added Mac OS support. Most - but not all - features from the iOS version are supported (see readme.md for details. Thanks go to Sushant Prakash for proving the concept).
- Added centerItemWhenSelected property to disable the auto-centering behaviour when tapping on item views.
- Added carousel:didSelectItemAtIndex: delegate method which is called when a user taps any item view in the carousel.
- Changed placeholder view behaviour slightly to be more flexible and intuitive.
- Bug and performance fixes to the depth sorting and positioning logic.
- Extended the example project to demonstrate the use of placeholder views and the new delegate method.
- Converted documentation and license files to markdown format.

Version 1.2.4

- Added ability to specify scroll animation duration.
- Added scrollByNumberOfItems method to programmatically scroll the carousel by a specified distance in either direction.
- Fixed retain cycle that prevented carousel from being deallocated properly.

Version 1.2.3

- Added contentOffset and viewpointOffset properties for adjusting layout and perspective.
- Made contentView property public.
- Fixed issue when inserting items into an empty carousel.
- Fixed issue when scrolling more than one step in a wrapped carousel.

Version 1.2.2

- Removed an iOS 4-specific API so that iCarousel will work on iOS 3.2.
- Fixed crash when removing last item in a carousel or inserting items into an empty carousel.

Version 1.2.1

- Fixed scrolling issue with carousel when last item is removed.
- Added insert/delete buttons to example project.

Version 1.2

- Smooth scrolling and acceleration, no longer based on UIScrollView.
- Added decelerationRate and bounces properties.
- Tap any visible item in the carousel to center it.
- Fixed crash on memory warning.
- Added wrap on/off selector to example.
- Example project is now a universal app.

Version 1.1.2

- Smoother animation when inserting items into carousel.
- iCarousel no longer modifies item view alpha when adding/removing items.

Version 1.1.1

- Fixed bug when inserting items into the carousel without animation.
- Fixed page scrolling bug on iOS 4.2 and earlier.

Version 1.1

- Added itemViews property.
- Added perspective property.
- Added scrollEnabled property.
- Added placeholder views feature.
- Fixed vanishing views bug in example project.

Version 1.0

- Initial release.