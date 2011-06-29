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

- Added ability to specify scroll animation duration
- Added scrollByNumberOfItems method to programmatically scroll the carousel by a specified distance in either direction
- Fixed retain cycle that prevented carousel from being deallocated properly

Version 1.2.3

- Added contentOffset and viewpointOffset properties for adjusting layout and perspective
- Made contentView property public
- Fixed issue when inserting items into an empty carousel
- Fixed issue when scrolling more than one step in a wrapped carousel 

Version 1.2.2

- Remove an iOS 4-specific API so that iCarousel will work on iOS 3.2
- Fixed crash when removing last item in a carousel or inserting items into an empty carousel

Version 1.2.1

- Fixed scrolling issue with carousel when last item is removed
- Added insert/delete buttons to example project

Version 1.2

- Smooth scrolling and acceleration, no longer based on UIScrollView
- Added decelerationRate and bounces properties
- Tap any visible item in the carousel to center it
- Fixed crash on memory warning
- Added wrap on/off selector to example
- Example project is now a universal app

Version 1.1.2

- Smoother animation when inserting items into carousel
- iCarousel no longer modifies item view alpha when adding/removing items

Version 1.1.1

- Fixed bug when inserting items into the carousel without animation
- Fixed page scrolling bug on iOS 4.2 and earlier

Version 1.1

- Added itemViews property
- Added perspective property
- Added scrollEnabled property
- Added placeholder views feature
- Fixed vanishing views bug in example project

Version 1.0

- Initial release