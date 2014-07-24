Purpose
--------------

iCarousel is a class designed to simplify the implementation of various types of carousel (paged, scrolling views) on iPhone, iPad and Mac OS. iCarousel implements a number of common effects such as cylindrical, flat and "CoverFlow" style carousels, as well as providing hooks to implement your own bespoke effects. Unlike many other "CoverFlow" libraries, iCarousel can work with any kind of view, not just images, so it is ideal for presenting paged data in a fluid and impressive way in your app. It also makes it extremely easy to swap between different carousel effects with minimal code changes.


Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 6.1 / Mac OS 10.8 (Xcode 4.6, Apple LLVM compiler 4.2)
* Earliest supported deployment target - iOS 5.0 / Mac OS 10.7
* Earliest compatible deployment target - iOS 4.3 / Mac OS 10.6

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this OS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


ARC Compatibility
------------------

As of version 1.8, iCarousel requires ARC. If you wish to use iCarousel in a non-ARC project, just add the -fobjc-arc compiler flag to the iCarousel.m class. To do this, go to the Build Phases tab in your target settings, open the Compile Sources group, double-click iCarousel.m in the list and type -fobjc-arc into the popover.

If you wish to convert your whole project to ARC, comment out the #error line in iCarousel.m, then run the Edit > Refactor > Convert to Objective-C ARC... tool in Xcode and make sure all files that you wish to use ARC for (including iCarousel.m) are checked.


Thread Safety
--------------

iCarousel is derived from UIView and - as with all UIKit components - it should only be accessed from the main thread. You may wish to use threads for loading or updating carousel contents or items, but always ensure that once your content has loaded, you switch back to the main thread before updating the carousel.


Installation
--------------

To use the iCarousel class in an app, just drag the iCarousel class files (demo files and assets are not needed) into your project and add the QuartzCore framework.


Chameleon Support
-------------------

iCarousel is now compatible with the Chameleon iOS-to-Mac conversion library (https://github.com/BigZaphod/Chameleon). To use iCarousel with Chameleon, add `USING_CHAMELEON` to your project's preprocessor macros. Check out the *Chameleon Demo* example project for how to port your iOS iCarousel app to Mac OS using Chameleon - the example demonstrates how to run the No Nib iPhone example on Mac OS using Chameleon. Note that tap-to-center doesn't currently work, and scrolling must be done using a two-fingered scroll gesture, not click-and-drag (both of these are due to features/limitations of the Chameleon UIGestureRecognizer implementation).


Carousel Types
--------------

iCarousel supports the following built-in display types:

- iCarouselTypeLinear
- iCarouselTypeRotary
- iCarouselTypeInvertedRotary
- iCarouselTypeCylinder
- iCarouselTypeInvertedCylinder
- iCarouselTypeWheel
- iCarouselTypeInvertedWheel
- iCarouselTypeCoverFlow
- iCarouselTypeCoverFlow2
- iCarouselTypeTimeMachine
- iCarouselTypeInvertedTimeMachine

You can also implement your own bespoke carousel styles using `iCarouselTypeCustom` and the `carousel:itemTransformForOffset:baseTransform:` delegate method.

NOTE: The difference between `iCarouselTypeCoverFlow` and `iCarouselTypeCoverFlow2` types is quite subtle, however the logic for `iCarouselTypeCoverFlow2` is substantially more complex. If you flick the carousel they are basically identical, but if you drag the carousel slowly with your finger the difference should be apparent. `iCarouselTypeCoverFlow2` is designed to simulate the standard Apple CoverFlow effect as closely as possible and may change subtly in future in the interests of that goal.


Properties
--------------

The iCarousel has the following properties (note: for Mac OS, substitute NSView for UIView when using properties):

	@property (nonatomic, weak) IBOutlet id<iCarouselDataSource> dataSource;

An object that supports the iCarouselDataSource protocol and can provide views to populate the carousel.

	@property (nonatomic, weak) IBOutlet id<iCarouselDelegate> delegate;

An object that supports the iCarouselDelegate protocol and can respond to carousel events and layout requests.

	@property (nonatomic, assign) iCarouselType type;

Used to switch the carousel display type (see above for details).

	@property (nonatomic, assign) CGFloat perspective;

Used to tweak the perspective foreshortening effect for the various 3D carousel views. Should be a negative value, less than 0 and greater than -0.01. Values outside of this range will yield very strange results. The default is -1/500, or -0.005;

	@property (nonatomic, assign) CGSize contentOffset;

This property is used to adjust the offset of the carousel item views relative to the center of the carousel. It defaults to CGSizeZero, meaning that the carousel items are centered. Changing this value moves the carousel items *without* changing their perspective, i.e. the vanishing point moves with the carousel items, so if you move the carousel items down, it *does not* appear as if you are looking down on the carousel.

	@property (nonatomic, assign) CGSize viewpointOffset;

This property is used to adjust the user viewpoint relative to the carousel items. It has the opposite effect to adjusting the contentOffset, i.e. if you move the viewpoint up then the carousel appears to move down. Unlike the contentOffset, moving the viewpoint also changes the perspective vanishing point relative to the carousel items, so if you move the viewpoint up, it will appear as if you are looking down on the carousel.

	@property (nonatomic, assign) CGFloat decelerationRate;

The rate at which the carousel decelerates when flicked. Higher values mean slower deceleration. The default value is 0.95. Values should be in the range 0.0 (carousel stops immediately when released) to 1.0 (carousel continues indefinitely without slowing down, unless it reaches the end).

	@property (nonatomic, assign) BOOL bounces;

Sets whether the carousel should bounce past the end and return, or stop dead. Note that this has no effect on carousel types that are designed to wrap, or where the carouselShouldWrap delegate method returns YES.

	@property (nonatomic, assign) CGFloat bounceDistance;

The maximum distance that a non-wrapped carousel will bounce when it overshoots the end. This is measured in multiples of the itemWidth, so a value of 1.0 would means the carousel will bounce by one whole item width, a value of 0.5 would be half an item's width, and so on. The default value is 1.0;

	@property (nonatomic, assign, getter = isScrollEnabled) BOOL scrollEnabled;

Enables and disables user scrolling of the carousel. The carousel can still be scrolled programmatically if this property is set to NO.

    @property (nonatomic, readonly, getter = isWrapEnabled) BOOL wrapEnabled;

Returns YES if wrapping is enabled and NO if it isn't. This property is read only. If you wish to override the default value, implement the `carousel:valueForOption:withDefault:` delegate method and return a value for `iCarouselOptionWrap`.

    @property (nonatomic, assign, getter = isPagingEnabled) BOOL pagingEnabled;
    
Enables and disables paging. When paging is enabled, the carousel will stop at each item view as the user scrolls, much like the pagingEnabled property of a UIScrollView.

	@property (nonatomic, readonly) NSInteger numberOfItems;

The number of items in the carousel (read only). To set this, implement the `numberOfItemsInCarousel:` dataSource method. Note that not all of these item views will be loaded or visible at a given point in time - the carousel loads item views on demand as it scrolls.

	@property (nonatomic, readonly) NSInteger numberOfPlaceholders;

The number of placeholder views to display in the carousel (read only). To set this, implement the `numberOfPlaceholdersInCarousel:` dataSource method.

	@property (nonatomic, readonly) NSInteger numberOfVisibleItems;
	
The maximum number of carousel item views to be displayed concurrently on screen (read only). This property is important for performance optimisation, and is calculated automatically based on the carousel type and view frame. If you wish to override the default value, implement the `carousel:valueForOption:withDefault:` delegate method and return a value for iCarouselOptionVisibleItems.

	@property (nonatomic, strong, readonly) NSArray *indexesForVisibleItems;
	
An array containing the indexes of all item views currently loaded and visible in the carousel, including placeholder views. The array contains NSNumber objects whose integer values match the indexes of the views. The indexes for item views start at zero and match the indexes passed to the dataSource to load the view, however the indexes for any visible placeholder views will either be negative (less than zero) or greater than or equal to `numberOfItems`. Indexes for placeholder views in this array *do not* equate to the placeholder view index used with the dataSource.

	@property (nonatomic, strong, readonly) NSArray *visibleItemViews;

An array of all the item views currently displayed in the carousel (read only). This includes any visible placeholder views. The indexes of views in this array do not match the item indexes, however the order of these views matches the order of the visibleItemIndexes array property, i.e. you can get the item index of a given view in this array by retrieving the equivalent object from the visibleItemIndexes array (or, you can just use the `indexOfItemView:` method, which is much easier).

	@property (nonatomic, strong, readonly) UIView *contentView;

The view containing the carousel item views. You can add subviews to this view if you want to intersperse them with the carousel items. If you want a view to appear in front or behind all of the carousel items, you should add it directly to the iCarousel view itself instead. Note that the order of views inside the contentView is subject to frequent and undocumented change whilst the app is running. Any views added to the contentView should have their userInteractionEnabled property set to NO to prevent conflicts with iCarousel's touch event handling.

	@property (nonatomic, assign) CGFloat scrollOffset;
	
This is the current scroll offset of the carousel in multiples of the itemWidth. This value, rounded to the nearest integer, is the currentItemIndex value. You can use this value to position other screen elements while the carousel is in motion. The value can also be set if you wish to scroll the carousel to a particular offset programmatically. This may be useful if you wish to disable the built-in gesture handling and provide your own implementation.

	@property (nonatomic, readonly) CGFloat offsetMultiplier;

This is the offset multiplier used when the user drags the carousel with their finger. It does not affect programmatic scrolling or deceleration speed. This defaults to 1.0 for most carousel types, but defaults to 2.0 for the CoverFlow-style carousels to compensate for the fact that their items are more closely spaced and so must be dragged further to move the same distance. You cannot set this property directly, but you can override the default value by implementing the `carouselOffsetMultiplier:` delegate method.

	@property (nonatomic, assign) NSInteger currentItemIndex;

The index of the currently centered item in the carousel. Setting this property is equivalent to calling `scrollToItemAtIndex:animated:` with the animated argument set to NO. 

	@property (nonatomic, strong, readonly) UIView *currentItemView;
	
The currently centered item view in the carousel. The index of this view matches `currentItemIndex`.

	@property (nonatomic, readonly) CGFloat itemWidth;

The display width of items in the carousel (read only). This is derived automatically from the first view passed in to the carousel using the `carousel:viewForItemAtIndex:reusingView:` dataSource method. You can also override this value using the `carouselItemWidth:` delegate method, which will alter the space allocated for carousel items (but won't resize or scale the item views).

	@property (nonatomic, assign) BOOL centerItemWhenSelected;

When set to YES, tapping any item in the carousel other than the one matching the currentItemIndex will cause it to smoothly animate to the center. Tapping the currently selected item will have no effect. Defaults to YES.

	@property (nonatomic, assign) CGFloat scrollSpeed;
	
This is the scroll speed multiplier when the user flicks the carousel with their finger. Defaults to 1.0.

	@property (nonatomic, readonly) CGFloat toggle;
	
This property is used for the `iCarouselTypeCoverFlow2` carousel transform. It is exposed so that you can implement your own variants of the CoverFlow2 style using the `carousel:itemTransformForOffset:baseTransform:` delegate method.

	@property (nonatomic, assign) BOOL stopAtItemBoundary;
	
By default, the carousel will come to rest at an exact item boundary when it is flicked. If you set this property to NO, it will stop naturally and then - if scrollToItemBoundary is set to YES - scroll back or forwards to the nearest boundary.
	
	@property (nonatomic, assign) BOOL scrollToItemBoundary;

By default whenever the carousel stops moving it will automatically scroll to the nearest item boundary. If you set this property to NO, the carousel will not scroll after stopping and will stay wherever it is, even if it's not perfectly aligned on the current index. The exception to this is that if wrapping is disabled and `bounces` is set to YES then regardless of this setting, the carousel will automatically scroll back to the first or last item index if it comes to rest beyond the end of the carousel.

	@property (nonatomic, assign, getter = isVertical) BOOL vertical;

This property toggles whether the carousel is displayed horizontally or vertically on screen. All the built-in carousel types work in both orientations. Switching to vertical changes both the layout of the carousel and also the direction of swipe detection on screen. Note that custom carousel transforms are not affected by this property, however the swipe gesture direction will still be affected.

    @property (nonatomic, readonly, getter = isDragging) BOOL dragging;
    
Returns YES if user has started scrolling the carousel and has not yet released it.
    
    @property (nonatomic, readonly, getter = isDecelerating) BOOL decelerating;

Returns YES if the user isn't dragging the carousel any more, but it is still moving.

    @property (nonatomic, readonly, getter = isScrolling) BOOL scrolling;

Returns YES if the carousel is currently being scrolled programatically.

	@property (nonatomic, assign) BOOL ignorePerpendicularSwipes;

If YES, the carousel will ignore swipe gestures that are perpendicular to the orientation of the carousel. So for a horizontal carousel, vertical swipes will not be intercepted. This means that you can have a vertically scrolling scrollView inside a carousel item view and it will still function correctly. Defaults to YES.

	@property (nonatomic, assign) BOOL clipsToBounds;
	
This is actually not a property of iCarousel but is inherited from UIView. It's included here because it's a frequently missed feature. Set this to YES to prevent the carousel item views overflowing their bounds. You can set this property in Interface Builder by ticking the 'Clip Subviews' option. Defaults to NO.

    @property (nonatomic, assign) CGFloat autoscroll;

This property can be used to set the carousel scrolling at a constant speed. A value of 1.0 would scroll the carousel forwards at a rate of one item per second. The autoscroll value can be positive or negative and defaults to 0.0 (stationary). Autoscrolling will stop if the user interacts with the carousel, and will resume when they stop.


Methods
--------------

The iCarousel class has the following methods (note: for Mac OS, substitute NSView for UIView in method arguments):

	- (void)scrollToItemAtIndex:(NSInteger)index animated:(BOOL)animated;

This will center the carousel on the specified item, either immediately or with a smooth animation. For wrapped carousels, the carousel will automatically determine the shortest (direct or wraparound) distance to scroll. If you need to control the scroll direction, or want to scroll by more than one revolution, use the scrollByNumberOfItems method instead.

	- (void)scrollToItemAtIndex:(NSInteger)index duration:(NSTimeInterval)scrollDuration;

This method allows you to control how long the carousel takes to scroll to the specified index.

	- (void)scrollByNumberOfItems:(NSInteger)itemCount duration:(NSTimeInterval)duration;

This method allows you to scroll the carousel by a fixed distance, measured in carousel item widths. Positive or negative values may be specified for itemCount, depending on the direction you wish to scroll. iCarousel gracefully handles bounds issues, so if you specify a distance greater than the number of items in the carousel, scrolling will either be clamped when it reaches the end of the carousel (if wrapping is disabled) or wrap around seamlessly.

    - (void)scrollToOffset:(CGFloat)offset duration:(NSTimeInterval)duration;

This works the same way as `scrollToItemAtIndex:`, but allows you to scroll to a fractional offset. This may be useful if you wish to achieve a very precise animation effect. Note that if the `scrollToItemBoundary` property is set to YES, the carousel will automatically scroll to the nearest item index after you call this method. anyway.

    - (void)scrollByOffset:(CGFloat)offset duration:(NSTimeInterval)duration;
    
This works the same way as `scrollByNumberOfItems:`, but allows you to scroll by a fractional number of items. This may be useful if you wish to achieve a very precise animation effect. Note that if the `scrollToItemBoundary` property is set to YES, the carousel will automatically scroll to the nearest item index after you call this method anyway.
    
	- (void)reloadData;

This reloads all carousel views from the dataSource and refreshes the carousel display.

	- (UIView *)itemViewAtIndex:(NSInteger)index;
	
Returns the visible item view with the specified index. Note that the index relates to the position in the carousel, and not the position in the `visibleItemViews` array, which may be different. Pass a negative index or one greater than or equal to `numberOfItems` to retrieve placeholder views. The method only works for visible item views and will return nil if the view at the specified index has not been loaded, or if the index is out of bounds.

	- (NSInteger)indexOfItemView:(UIView *)view;
	
The index for a given item view in the carousel. Works for item views and placeholder views, however placeholder view indexes do not match the ones used by the dataSource and may be negative (see `indexesForVisibleItems` property above for more details). This method only works for visible item views and will return NSNotFound for views that are not currently loaded. For a list of all currently loaded views, use the `visibleItemViews` property.

	- (NSInteger)indexOfItemViewOrSubview:(UIView *)view

This method gives you the item index of either the view passed or the view containing the view passed as a parameter. It works by walking up the view hierarchy starting with the view passed until it finds an item view and returns its index within the carousel. If no currently-loaded item view is found, it returns NSNotFound. This method is extremely useful for handling events on controls embedded within an item view. This allows you to bind all your item controls to a single action method on your view controller, and then work out which item the control that triggered the action was related to. You can see an example of this technique in the *Controls Demo* example project.

    - (CGFloat)offsetForItemAtIndex:(NSInteger)index;

Returns the offset for the specified item index in multiples of `itemWidth` from the center position. This is the same value used for calculating the view transform and alpha, and can be used to customise item views based on their position in the carousel. This value can be expected to change for each view whenever the `carouselDidScroll:` delegate method is called.

    - (UIView *)itemViewAtPoint:(CGPoint)point;

Returns the frontmost item view at the specified point within the bounds of the carousel. Useful for implementing your own tap detection.

	- (void)removeItemAtIndex:(NSInteger)index animated:(BOOL)animated;

This removes an item from the carousel. The remaining items will slide across to fill the gap. Note that the data source is not automatically updated when this method is called, so a subsequent call to reloadData will restore the removed item.

	- (void)insertItemAtIndex:(NSInteger)index animated:(BOOL)animated;

This inserts an item into the carousel. The new item will be requested from the dataSource, so make sure that the new item has been added to the data source data before calling this method, or you will get duplicate items in the carousel, or other weirdness.

	- (void)reloadItemAtIndex:(NSInteger)index animated:(BOOL)animated;
	
This method will reload the specified item view. The new item will be requested from the dataSource. If the animated argument is YES, it will cross-fade from the old to the new item view, otherwise it will swap instantly.


Protocols
---------------

The iCarousel follows the Apple convention for data-driven views by providing two protocol interfaces, iCarouselDataSource and iCarouselDelegate. The iCarouselDataSource protocol has the following required methods (note: for Mac OS, substitute NSView for UIView in method arguments):

	- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel;

Return the number of items (views) in the carousel.

	- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view;

Return a view to be displayed at the specified index in the carousel. The `reusingView` argument works like a UIPickerView, where views that have previously been displayed in the carousel are passed back to the method to be recycled. If this argument is not nil, you can set its properties and return it instead of creating a new view instance, which will slightly improve performance. Unlike UITableView, there is no reuseIdentifier for distinguishing between different carousel view types, so if your carousel contains multiple different view types then you should just ignore this parameter and return a new view each time the method is called. You should ensure that each time the `carousel:viewForItemAtIndex:reusingView:` method is called, it either returns the reusingView or a brand new view instance rather than maintaining your own pool of recyclable views, as returning multiple copies of the same view for different carousel item indexes may cause display issues with the carousel.

The iCarouselDataSource protocol has the following optional methods:

	- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel;

Returns the number of placeholder views to display in the carousel. Placeholder views are intended to be used when the number of items in the carousel is too few to fill the carousel width, and you wish to display something in the empty space. They move with the carousel and behave just like any other carousel item, but they do not count towards the numberOfItems value, and cannot be set as the currently selected item. Placeholders are hidden when wrapping is enabled. Placeholders appear on either side of the carousel items. For n placeholder views, the first n/2 items will appear to the left of the item views and the next n/2 will appear to the right. You can have an odd number of placeholders, in which case the carousel will be asymmetrical.

	- (UIView *)carousel:(iCarousel *)carousel placeholderViewAtIndex:(NSUInteger)index reusingView:(UIView *)view;

Return a view to be displayed as the placeholder view. Works the same way as `carousel:viewForItemAtIndex:reusingView:`. Placeholder reusingViews are stored in a separate pool to the reusingViews used for regular carousel, so it's not a problem if your placeholder views are different to the item views.

The iCarouselDelegate protocol has the following optional methods:

	- (void)carouselWillBeginScrollingAnimation:(iCarousel *)carousel;
	
This method is called whenever the carousel will begin an animated scroll. This can be triggered programatically or automatically after the user finishes scrolling the carousel, as the carousel re-aligns itself.
	
	- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel;
	
This method is called when the carousel ends an animated scroll.
	
	- (void)carouselDidScroll:(iCarousel *)carousel;

This method is called whenever the carousel is scrolled. It is called regardless of whether the carousel was scrolled programatically or through user interaction.

	- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel;

This method is called whenever the carousel scrolls far enough for the currentItemIndex property to change. It is called regardless of whether the item index was updated programatically or through user interaction.

	- (void)carouselWillBeginDragging:(iCarousel *)carousel;
	
This method is called when the user begins dragging the carousel. It will not fire if the user taps/clicks the carousel, or if the carousel is scrolled programmatically.
	
	- (void)carouselDidEndDragging:(iCarousel *)carousel willDecelerate:(BOOL)decelerate;
	
This method is called when the user stops dragging the carousel. The willDecelerate parameter indicates whether the carousel is travelling fast enough that it needs to decelerate before it stops (i.e. the current index is not necessarily the one it will stop at) or if it will stop where it is. Note that even if willDecelerate is NO, the carousel will still scroll automatically until it aligns exactly on the current index. If you need to know when it has stopped moving completely, use the carouselDidEndScrollingAnimation delegate method.
	
	- (void)carouselWillBeginDecelerating:(iCarousel *)carousel;
	
This method is called when the carousel starts decelerating. it will typically be called immediately after the carouselDidEndDragging:willDecelerate: method, assuming willDecelerate was YES.
	
	- (void)carouselDidEndDecelerating:(iCarousel *)carousel;

This method is called when the carousel finishes decelerating and you can assume that the currentItemIndex at this point is the final stopping value. Unlike previous versions, the carousel will now stop exactly on the final index position in most cases. The only exception is on non-wrapped carousels with bounce enabled, where, if the final stopping position is beyond the end of the carousel, the carousel will then scroll automatically until it aligns exactly on the end index. For backwards compatibility, the carousel will always call `scrollToItemAtIndex:animated:` after it finishes decelerating. If you need to know for certain when the carousel has stopped moving completely, use the `carouselDidEndScrollingAnimation` delegate method.

	- (CGFloat)carouselItemWidth:(iCarousel *)carousel;

Returns the width of each item in the carousel - i.e. the spacing for each item view. If the method is not implemented, this defaults to the width of the first item view that is returned by the `carousel:viewForItemAtIndex:reusingView:` dataSource method. This method should only be used to crop or pad item views if the views returned from `carousel:viewForItemAtIndex:reusingView:` are not correct (e.g. if the views are differing sizes, or include a drop shadow or outer glow in their background image that affects their size) - if you just want to space out the views a bit then it's better to use the `iCarouselOptionSpacing` value instead.

	- (CATransform3D)carousel:(iCarousel *)carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform;

This method can be used to provide a custom transform for each carousel view. The offset argument is the distance of the view from the middle of the carousel. The currently centred item view would have an offset of 0.0, the one to the right would have an offset value of 1.0, the one to the left an offset value of -1.0, and so on. To implement the linear carousel style, you would therefore simply multiply the offset value by the item width and use it as the x value of the transform. This method is only called if the carousel type is iCarouselTypeCustom.

	- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value;

This method is used to customise the parameters of the standard carousel types. By implementing this method, you can tweak options such as the number of items displayed in a circular carousel, or the amount of tilt in a coverflow carousel, as well as whether the carousel should wrap and if it should fade out at the ends, etc. For any option you are not interested in tweaking, just return the default value. The meaning of these options is listed below under *iCarouselOption values*. Check the *Options Demo* for an advanced example of using this method.

	- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index;

This method will fire if the user taps any carousel item view (not including placeholder views), including the currently selected view. This method will not fire if the user taps a control within the currently selected view (i.e. any view that is a subclass of UIControl).

	- (BOOL)carousel:(iCarousel *)carousel shouldSelectItemAtIndex:(NSInteger)index;
	
This method will fire if the user taps any carousel item view (not including placeholder views), including the currently selected view. The purpose of a method is to give you the opportunity to ignore a tap on the carousel. If you return YES from the method, or don't implement it, the tap will be processed as normal and the `carousel:didSelectItemAtIndex:` method will be called. If you return NO, the carousel will ignore the tap and it will continue to propagate up the view hierarchy. This is a good way to prevent the carousel intercepting tap events intended for processing by another view.


iCarouselOption values
----------------------------

These are the tweakable options for standard carousels. Check the *Options Demo* for an example of the effect that these parameters have.

    iCarouselOptionWrap
    
A boolean indicating whether the carousel should wrap when it scrolls to the end. Return YES if you want the carousel to wrap around when it reaches the end, and NO if you want it to stop. Generally, circular carousel types will wrap by default and linear ones won't. Don't worry that the return type is a floating point value - any value other than 0.0 will be treated as YES.

    iCarouselOptionShowBackfaces
    
For some carousel types, e.g. iCarouselTypeCylinder, the rear side of some views can be seen (iCarouselTypeInvertedCylinder now hides the back faces by default). If you wish to hide the backward-facing views you can return NO for this option. To override the default back-face hiding for the iCarouselTypeInvertedCylinder, you can return YES. This option may also be useful for custom carousel transforms that cause the back face of views to be displayed.

    iCarouselOptionOffsetMultiplier
    
The offset multiplier to use when the user drags the carousel with their finger. It does not affect programmatic scrolling or deceleration speed. This defaults to 1.0 for most carousel types, but defaults to 2.0 for the CoverFlow-style carousels to compensate for the fact that their items are more closely spaced and so must be dragged further to move the same distance.

	iCarouselOptionVisibleItems
	
This is the maximum number of item views (including placeholders) that should be visible in the carousel at once. Half of this number of views will be displayed to either side of the currently selected item index. Views beyond that will not be loaded until they are scrolled into view. This allows for the carousel to contain a very large number of items without adversely affecting performance. iCarousel chooses a suitable default value based on the carousel type, however you may wish to override that value using this property (e.g. if you have implemented a custom carousel type).

	iCarouselOptionCount
	
The number of items to be displayed in the Rotary, Cylinder and Wheel transforms. Normally this is calculated automatically based on the view size and number of items in the carousel, but you can override this if you want more precise control of the carousel appearance. This property is used to calculate the carousel radius, so another option is to manipulate the radius directly.

    iCarouselOptionArc
    
The arc of the Rotary, Cylinder and Wheel transforms (in radians). Normally this defaults to 2*M_PI (a complete circle) but you can specify a smaller value, so for example a value of M_PI will create a half-circle or cylinder. This property is used to calculate the carousel radius and angle step, so another option is to manipulate those values directly.
    
    iCarouselOptionRadius
    
The radius of the Rotary, Cylinder and Wheel transforms in pixels/points. This is usually calculated so that the number of visible items exactly fits into the specified arc. You can manipulate this value to increase or reduce the item spacing (and the radius of the circle).
    
	iCarouselOptionAngle
	
The angular step between each item in the Rotary, Cylinder and Wheel transforms (in radians). Manipulating this value without changing the radius will cause a gap at the end of the carousel or cause the items to overlap.
	
    iCarouselOptionTilt

The tilt applied to the non-centered items in the CoverFlow, CoverFlow2 and TimeMachine carousel types. This value should be in  the range 0.0 to 1.0.

    iCarouselOptionSpacing

The spacing between item views. This value is multiplied by the item width (or height, if the carousel is vertical) to get the total space between each item, so a value of 1.0 (the default) means no space between views (unless the views already include padding, as they do in many of the example projects).

    iCarouselOptionFadeMin
    iCarouselOptionFadeMax
    iCarouselOptionFadeRange
    iCarouselOptionFadeMinAlpha

These four options control the fading out of carousel item views based on their offset from the currently centered item. FadeMin is the minimum negative offset an item view can reach before it begins to fade. FadeMax is the maximum positive offset a view can reach before if begins to fade. FadeRange is the distance over which the fadeout occurs, measured in multiples of an item width (defaults to 1.0), and FadeMinAlpha is the minimum alpha value to which the views will fade (defaults to 0.0 - fully transparent).


Detecting Taps on Item Views
----------------------------

There are two basic approaches to detecting taps on views in iCarousel on iOS. The first approach is to simply use the `carousel:didSelectItemAtIndex:` delegate method, which fires every time an item is tapped. If you are only interested in taps on the currently centered item, you can compare the `currentItemIndex` property against the index parameter of this method.

Alternatively, if you want a little more control you can supply a UIButton or UIControl as the item view and handle the touch interactions yourself. See the *Buttons Demo* example project for an example of how this is done (doesn't work on Mac OS; see below).

You can also nest UIControls within your item views and these will receive touches as expected (see the *Controls Demo* example project for an example).

If you wish to detect other types of interaction such as swipes, double taps or long presses, the simplest way is to attach a UIGestureRecognizer to your item view or its subviews before passing it to the carousel.

Note that taps and gestures will be ignored on any item view except the currently selected one, unless you set the `centerItemWhenSelected` property to NO.

On Mac OS there is no easy way to embed controls within iCarousel item views currently. You cannot just supply an NSButton as or inside your item view because the transforms applied to the item views mean that hit detection doesn't work properly. I'm investigating possible solutions to this (if you know a good way to fix this, please get in touch, or fork the project on github).

Accessibility
-------------
This implementation is based on the approach of making part of the UI not subject to VoiceOver gestures. 
As a result VoiceOver doesn’t "steal" the iCarousel single finger swipe. Delegate methods are used to process additional Accessibility announcement upon swipe or single tap. Double tap is used for item selection with VoiceOver on. On thing that should be noted is that due to the fact that the usual VoiceOver single finger swipe gesture does not "exit" the carousel, additional work is required in the iCarousel's container view in order to fully support Accessibility.
Credits to Boris Dusek for his answer on  http://stackoverflow.com/questions/20710991/when-voiceover-is-on-is-there-a-way-an-app-can-detect-a-single-finger-left-rig?rq=1 

Example projects
------------------

iCarousel includes a number of example projects to help you get started. Here is a lift and brief description for each:

    Basic iOS Example
    
This is a very simple example for iOS that demonstrates setting up a carousel with the iCarouselCoverflow2 type.
    
    iOS Demo
    
This is a more complex iOS demo app that shows off all the different carousel types and additional features such as dynamic insertion/deletion of items.

    Mac Demo

This is a Mac OS port of the iOS Demo example, which replicates all the same functionality.

    Buttons Demo

This example demonstrates how to use UIButtons as your item views on iOS and correctly handle the events.

    Controls Demo
    
This example demonstrates how to nest controls within your item views on iOS and correctly handle the events, as well as how to load complex item views from a nib file instead of generating them in code.

    Multiple Carousels

This example demonstrates how to use multiple carousels within a single view controller.

    No Nib Demo
    
This example demonstrates how to set up iCarousel without using a nib file on iOS.

    Storyboard Demo

This example demonstrates how to set up iCarousel using Storyboards on iOS 5 and above.

    Offsets Demo
    
This example demonstrates how to use the `contentOffset` and `viewpointOffset` properties, and the effect they have.
    
    Options Demo

This example demonstrates how to customise the appearance of each carousel type using the iCarouselOption API.

    Fading Demo
    
This example demonstrates how to use the iCarouselOption API to implement a nice looking fade out effect at the edges of the carousel.

    Dynamic View Reflections
    
This example demonstrates how to use the ReflectionView class (https://github.com/nicklockwood/ReflectionView) to dynamically generate reflections for your item views. This is applicable to item views that contain subviews or controls. For item views that are just images, it's better to use the approach shown in the *Dynamic Image Effects* example.

    Dynamic Image Effects
    
This example demonstrates how to use the FXImageView class (https://github.com/nicklockwood/FXImageView) to dynamically generate reflections and drop shadows for your carousel images.

    Dynamic Downloads
    
This example demonstrates how to use the AsyncImageView class (https://github.com/nicklockwood/AsyncImageView) to dynamically download remote images and display them in a carousel without blocking the main thread or negatively affecting performance.

    Downloads & Effects

This example demonstrates how to use the FXImageView class (https://github.com/nicklockwood/FXImageView) to download images on the fly and apply reflections and drop shadows to them in real time.


FAQ
------------

    Q. I upgrade to the new version of iCarousel and it broke my project, how do I get the old one back?
    A. Every previous release of iCarousel is tagged as a separate download on github - look in the tags tab.

    Q. Can I use iCarousel without a nib file?
    A. Yes, check out the *No Nib Demo* for how to set up iCarousel without nibs
    
    Q. Can I use iCarousel with a Storyboard?
    A. Yes, this is pretty much the same as using it with a nib file. Check out the *Storyboard Demo* to see how it's done.
    
    Q. How do I prevent iCarousel item views from overflowing their bounds?
    A. Set the `clipsToBounds` property to YES on your iCarousel view. You can set this property in Interface Builder by ticking the 'Clip Subviews' option.
    
    Q. I'm getting weird issues where views turn up at the wrong points in the carousel. What's going on?
    A. You're probably recycling views in your `carousel:viewForItemAtIndex:reusingView:` using the `reusingView` parameter without setting the view contents each time. Study the demo app more closely and make sure you aren't doing all your item view setup in the wrong place.
    
    Q. I'm loading 50 images in my carousel and I keep running out of memory. How can I fix it?
    A. The trick is to load the views on a background thread as the carousel is scrolling instead of loading them all in advance. Check out the *Dynamic Downloads* example for how to do this using the AsyncImageView library. The example is using remote image URLs, but the exact same approach will work just as well for locally hosted images in your app - just create local file URLs using `[NSURL fileUrlWithPath:...]`.

    Q. Can I use multiple carousels in the same view controller?
    A. Yes, check out the *Multiple Carousels* example for how to do this.
    
    Q. I can't figure out how to use iCarousel in my project, is there a simple example?
    A. Yes, check out the *Basic iOS Example* project for a bare-bones implementation. If you're still not clear what's going on, read up about how UITableView works, and once you understand that, iCarousel will make more sense.
    
    Q. In the iCarouselTypeCylinder carousel, the back-side of the item views is visible. How can I hide these views?
    A. You can either return NO as the value for the `iCarouselOptionShowBackfaces` option, or set the `view.layer.doubleSided` property of your item views to `NO` to hide them when they are facing backwards.
    
    Q. What is the `reusingView` property for in the `carousel:viewForItemAtIndex:reusingView:` dataSource method?
    A. You can improve iCarousel performance by recycling item views when they move offscreen instead of creating a new one each time it's needed. Check if this value is nil, and if not you can re-use this view instead of creating a new one. Note however that the view will still have any subviews or properties you added when it was first created, so be careful not to introduce leaks by re-adding those views each time. You may find it's easier and safer to ignore this paramater and create a fresh view each time if you're not sure what you are doing.
    
    Q. If the views in my carousel all have completely different layouts, should I still use the `reusingView` parameter?
    A. Probably not, and unless you have hundreds of views in your carousel, it's unlikely to be worth the trouble.

    Q. How can I make iCarousl behave like a UIScrollView with paging enabled?
    A. As of version 1.8, iCarousel has a pagingEnabled property that emulates the behaviour of a UIScrollView (see the *Paging Example* project). The bounce physics are not quite the same though, and you may want to consider using the SwipeView library instead (https://github.com/nicklockwood/SwipeView) which is very similar to iCarousel, but based on a UIScrollView under the hood.
    
    Q. I want my carousel items to have a real reflection, but the reflection in the examples is just drawn on. How can I render reflections dynamically?
    A. iCarousel doesn't have built-in reflection support, but you can use some additional libraries to do this. Check out the *Dynamic View Reflections* and  *Dynamic Image Effects* examples.
    
    Q. I want to download a bunch of images on the fly and display them in my carousel. How can I do that?
    A. Downloading images asynchronously and displaying them is quite complex. You can use my AsyncImageView library to simplify the process. Check out the *Dynamic Downloads* example.
    
    Q. What if I want to download images on the fly *and* add a reflection? Can I combine the ReflectionView and AsyncImageView classes?
    A. Technically yes, but if you are downloading images you'd be better off using the FXImageView class instead of ReflectionView. Check out the *Downloads & Reflections* example.
    
    Q. The edges of my item views look jaggy. Is there any way to smooth/antialias them?
    A. If you include (at least) a single pixel of transparent space around the edge of your item view images then iOS will smooth them automatically. This is because iOS automatically antialiases the pixels inside images, but doesn't antialias the edges of views. Even if your item views are a flat color, it's worth adding a background image of the same color to the views in order to get the smoothing effect.
