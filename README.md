Purpose
--------------

iCarousel is a class designed to simplify the implementation of various types of carousel (paged, scrolling views) on iPhone, iPad and Mac OS. iCarousel implements a number of common effects such as cylindrical, flat and "CoverFlow" style carousels, as well as providing hooks to implement your own bespoke effects. Unlike many other "CoverFlow" libraries, iCarousel can work with any kind of view, not just images, so it is ideal for presenting paged data in a fluid and impressive way in your app. It also makes it extremely easy to swap between different carousel effects with minimal code changes.

*Special thanks go to Sushant Prakash (https://github.com/sushftw) for the Mac port.*

Not all features of iCarousel are currently supported on Mac OS. I hope to address this in future. Please refer to the documentation below for details.


Supported iOS & SDK Versions
-----------------------------

* Supported build target - iOS 5.0 (Xcode 4.2)
* Earliest supported deployment target - iOS 4.0 (Xcode 4.2)
* Earliest compatible deployment target - iOS 3.2

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this iOS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


Installation
--------------

To use the iCarousel class in an app, just drag the iCarousel class files (demo files and assets are not needed) into your project and add the QuartzCore framework.


ARC Compatibility
------------------

iCarousel does not use automatic reference counting, but will convert using the ARC migration tool without any issues. However, in the interests of avoiding modifying the iCarousel library, which may cause unknown bugs or problems later when upgrading to a new version, a better approach is to specify in your ARC project that iCarousel's files should be excluded from the ARC validation process. To do that:

1) Go to Project Settings, under Build Phases > Compile Sources
2) Select the iCarousel.m file and add the -fno-objc-arc compiler flag


Carousel Types
--------------

iCarousel supports the following built-in display types:

- iCarouselTypeLinear
- iCarouselTypeRotary
- iCarouselTypeInvertedRotary
- iCarouselTypeCylinder
- iCarouselTypeInvertedCylinder
- iCarouselTypeCoverFlow
- iCarouselTypeCoverflow2

You can also implement your own bespoke carousel styles using `iCarouselTypeCustom` and the `carousel:transformForItemView:withOffset:` delegate method.

NOTE: The difference between `iCarouselTypeCoverFlow` and `iCarouselTypeCoverFlow2` types is quite subtle, however the logic for `iCarouselTypeCoverFlow2` is substantially more complex. If you flick the carousel they are basically identical, but if you drag the carousel slowly with your finger the difference should be apparent. `iCarouselTypeCoverFlow2` is designed to simulate the standard Apple CoverFlow effect as closely as possible and may change subtly in future in the interests of that goal.


Properties
--------------

The iCarousel has the following properties (note: for Mac OS, substitute NSView for UIView when using properties):

	@property (nonatomic, assign) IBOutlet id<iCarouselDataSource> dataSource;

An object that supports the iCarouselDataSource protocol and can provide views to populate the carousel.

	@property (nonatomic, assign) IBOutlet id<iCarouselDelegate> delegate;

An object that supports the iCarouselDelegate protocol and can respond to carousel events and layout requests.

	@property (nonatomic, assign) iCarouselType type;

Used to switch the carousel display type (see above for details).

	@property (nonatomic, assign) CGFloat perspective;

Used to tweak the perspective foreshortening effect for the various 3D carousel views. Should be a negative value, less than 0 and greater than -0.01. Values outside of this range will yield very strange results. The default is -1/500, or -0.005;

	@property (nonatomic, assign) CGSize contentOffset;

This property is used to adjust the offset of the carousel item views relative to the center of the carousel. It defaults to CGSizeZero, meaning that the carousel items are centered. Changing this value moves the carousel items *without* changing their perspective, i.e. the vanishing point moves with the carousel items, so if you move the carousel items down, it *does not* appear as if you are looking down on the carousel.

	@property (nonatomic, assign) CGSize viewpointOffset;

This property is used to adjust the user viewpoint relative to the carousel items. It has the opposite effect to adjusting the contentOffset, i.e. if you move the viewpoint up then the carousel appears to move down. Unlike the contentOffset, moving the viewpoint also changes the perspective vanishing point relative to the carousel items, so if you move the viewpoint up, it will appear as if you are looking down on the carousel.

Note that the viewpointOffset transform is concatenated with the carousel item transform used by the carousel (or the custom transform you have supplied using the transformForItemView delegate method), so if the carousel items are rotated or scaled then this may not have the desired effect.

	@property (nonatomic, assign) CGFloat decelerationRate;

The rate at which the carousel decelerates when flicked. Higher values mean slower deceleration. The default value is 0.95. Values should be in the range 0.0 (carousel stops immediately when released) to 1.0 (carousel continues indefinitely without slowing down, unless it reaches the end).

	@property (nonatomic, assign) BOOL bounces;

Sets whether the carousel should bounce past the end and return, or stop dead. Note that this has no effect on carousel types that are designed to wrap, or where the carouselShouldWrap delegate method returns YES.

	@property (nonatomic, assign) CGFloat bounceDistance;

The maximum distance that a non-wrapped carousel will bounce when it overshoots the end. This is measured in multiples of the itemWidth, so a value of 1.0 would means the carousel will bounce by one whole item width, a value of 0.5 would be half an item's width, and so on. The default value is 1.0;

	@property (nonatomic, assign) BOOL scrollEnabled;

Enables and disables user scrolling of the carousel. The carousel can still be scrolled programmatically if this property is set to NO.

	@property (nonatomic, readonly) NSInteger numberOfItems;

The number of items currently displayed in the carousel (read only). To set this, implement the `numberOfItemsInCarousel:` dataSource method.

	@property (nonatomic, readonly) NSInteger numberOfPlaceholders;

The number of placeholder views to display in the carousel (read only). To set this, implement the `numberOfPlaceholdersInCarousel:` dataSource method.

	@property (nonatomic, readonly) NSInteger numberOfVisibleItems;
	
The maximum number of carousel item views to be displayed concurrently on screen (read only). To set this, implement the `numberOfVisibleItemsInCarousel:` dataSource method. If the dataSource method is not implemented, this will be equal to the numberOfItems + numberOfPlaceholders;

	@property (nonatomic, retain, readonly) NSArray *indexesForVisibleItems;
	
An array containing the indexes of all item views currently visible in the carousel, including placeholder views. The array contains NSNumber objects whose integer values match the indexes of the views. The indexes for item views start at zero and match the indexes passed to the dataSource to load the view, however the indexes for any visible placeholder views will either be negative (less than zero) or greater than or equal to `numberOfItems`. Indexes for placeholder views in this array do not equate to the placeholder view index used with the dataSource.

	@property (nonatomic, retain, readonly) NSArray *visibleItemViews;

An array of all the item views currently displayed in the carousel (read only). This includes any visible placeholder views. The indexes of views in this array do not match the item indexes, however the order of these views matches the order of the visibleItemIndexes array property, i.e. you can get the item index of a given view in this array by retrieving the equivalent object from the visibleItemIndexes array (or, you can just use the `indexOfItemView:` method, which is much easier).

	@property (nonatomic, retain, readonly) UIView *contentView;

The view containing the carousel item views. You can add subviews to this view if you want to intersperse them with the carousel items. If you want a view to appear in front or behind all of the carousel items, you should add it directly to the iCarousel view itself instead. Note that the order of views inside the contentView is subject to frequent and undocumented change while the app is running. Any views added to the contentView should have their userInteractionEnabled property set to NO to prevent conflicts with iCarousel's touch event handling.

	@property (nonatomic, readonly) CGFloat scrollOffset;
	
This is the current offset in pixels of the carousel. This value, divided by the itemWidth is the currentItemIndex value. You can use this value to position other screen elements while the carousel is in motion.

	@property (nonatomic, readonly) CGFloat offsetMultiplier;

This is the offset multiplier used when the user drags the carousel with their finger. It does not affect programmatic scrolling or deceleration speed. This defaults to 1.0 for most carousel types, but defaults to 2.0 for the CoverFlow-style carousels to compensate for the fact that their items are more closely spaced and so must be dragged further to move the same distance. You cannot set this property directly, but you can override the default value by implementing the `carouselOffsetMultiplier:` delegate method.

	@property (nonatomic, readonly) NSInteger currentItemIndex;

The index of the currently centered item in the carousel (read only). To change this, use the `scrollToItemAtIndex:` methods. 

	@property (nonatomic, retain, readonly) UIView *currentItemView;
	
The currently centered item view in the carousel. The index of this view matches `currentItemIndex`. 

	@property (nonatomic, readonly) CGFloat itemWidth;

The display width of items in the carousel (read only). This is derived automatically from the first view passed in to the carousel using the `carousel:viewForItemAtIndex:` dataSource method. You can also override this value using the `carouselItemWidth:` delegate method, which will alter the spacing between carousel items (but won't resize or scale the item views).

	@property (nonatomic, assign) BOOL centerItemWhenSelected;

When set to YES, tapping any item in the carousel other than the one matching the currentItemIndex will cause it to smoothly animate to the center. Tapping the currently selected item will have no effect. Defaults to YES. **This property is currently only supported on the iOS version of iCarousel.**

	@property (nonatomic, assign) CGFloat scrollSpeed;
	
This is the scroll speed multiplier when the user flicks the carousel with their finger. Defaults to 1.0.

	@property (nonatomic, readonly) CGFloat toggle;
	
This property is used for the `iCarouselTypeCoverFlow2` carousel transform. It is exposed so that you can implement your own variants of the CoverFlow2 style using the `carousel:transformForItemView:withOffset` delegate method.

	@property (nonatomic, assign) BOOL stopAtItemBoundary;
	
By default, the carousel will come to rest at an exact item boundary when it is flicked. If you set this property to NO, it will stop naturally and then - if scrollToItemBoundary is set to YES - scroll back or forwards to the nearest boundary.
	
	@property (nonatomic, assign) BOOL scrollToItemBoundary;

By default whenever the carousel stops moving it will automatically scroll to the nearest item boundary. If you set this property to NO, the carousel will not scroll after stopping and will stay wherever it is, even if it's not perfectly aligned on the current index. The exception to this is that if wrapping is disabled and `bounces` is set to YES then regardless of this setting, the carousel will automatically scroll back to the first or last item index if it comes to rest beyond the end of the carousel.

	@property (nonatomic, assign) BOOL clipToBounds;
	
This is actually not a property of iCarousel but is inherited from UIView. It's included here because it's a frequently missed feature. Set this to YES to prevent the carousel item views overflowing their bounds. You can set this property in Interface Builder by ticking the 'Clip Subviews' option. Defaults to NO.


Methods
--------------

The iCarousel class has the following methods (note: for Mac OS, substitute NSView for UIView in method arguments):

	- (void)scrollToItemAtIndex:(NSInteger)index animated:(BOOL)animated;

This will center the carousel on the specified item, either immediately or with a smooth animation. For wrapped carousels, the carousel will automatically determine the shortest (direct, or wraparound) distance to scroll. If you need to control the scroll direction, or want to scroll by more than one revolution, use the scrollByNumberOfItems method instead.

	- (void)scrollToItemAtIndex:(NSInteger)index duration:(NSTimeInterval)scrollDuration;

This method allows you to control how long the carousel takes to scroll to the specified index.

	- (void)scrollByNumberOfItems:(NSInteger)itemCount duration:(NSTimeInterval)duration;

This method allows you to scroll the carousel by a fixed distance, measured in carousel item widths. Positive or negative values may be specified for itemCount, depending on the direction you wish to scroll. iCarousel gracefully handles bounds issues, so if you specify a distance greater than the number of items in the carousel, scrolling will either be clamped when it reaches the end of the carousel (if wrapping is disabled) or wrap around seamlessly.

	- (void)reloadData;

This reloads all carousel views from the dataSource and refreshes the carousel display.

	- (UIView *)itemViewAtIndex:(NSInteger)index;
	
Returns the visible item view with the specified index. Note that the index relates to the position in the carousel, and not the position in the `visibleItemViews` array, which may be different. Pass a negative index or one greater than or equal to `numberOfItems` to retrieve placeholder views. The method only works for visible item views and will return nil if the view at the specified index has not been loaded, or if the index is out of bounds.

	- (NSInteger)indexOfItemView:(UIView *)view;
	
The index for a given item view in the carousel. Works for item views and placeholder views, however placeholder view indexes do not match the ones used by the dataSource and may be negative (see `indexesForVisibleItems` property above for more details). This method only works for visible item views and will return NSNotFound for views that are not currently loaded. For a list of all currently loaded views, use the `visibleItemViews` property.

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

	- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index;

Return a view to be displayed at the specified index in the carousel. Unlike UITableView, there is no dequeuing system for iCarousel item views, but you should ensure that each time the `carousel:viewForPageAtIndex:` method is called, it returns a new view instance, as returning multiple copies of the same view may cause display issues with the carousel.

The iCarouselDataSource protocol has the following optional methods:

	- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel;

Returns the number of placeholder views to display in the carousel. Placeholder views are intended to be used when the number of items in the carousel is too few to fill the carousel width, and you wish to display something in the empty space. They move with the carousel and behave just like any other carousel item, but they do not count towards the numberOfItems value, and cannot be set as the currently selected item. Placeholders are hidden when wrapping is enabled. Placeholders appear on either side of the carousel items. For n placeholder views, the first n/2 items will appear to the left of the item views and the next n/2 will appear to the right. You can have an odd number of placeholders, in which case the carousel will be asymmetrical. **Note: the behaviour for placeholders has changed since version 1.2.x - the number of placeholders value now refers to the total number, not the number on each side.**

	- (UIView *)carousel:(iCarousel *)carousel placeholderViewAtIndex:(NSUInteger)index;

Return a view to be displayed as the placeholder view. As with the regular item views, you must return a unique view instance for each call to `carouselPlaceholderView:` to avoid display issues. **Note: the protocol and behaviour for placeholders has changed since version 1.2.x - they are no longer mirrored, so it is possible to provide visually distinct views for each placeholder.**

	- (NSUInteger)numberOfVisibleItemsInCarousel:(iCarousel *)carousel;
	
This is the maximum number of item views (including placeholders) that should be visible in the carousel at once. Half of this number of views will be displayed to either side of the currently selected item index. Views beyond that will not be loaded until they are scrolled into view. This allows for the carousel to contain a very large number of items without adversely affecting performance. The numberOfVisibleItems should be a positive, odd number. If this method is not implemented, all item views and placeholder views will be drawn every frame, which will result in significant degrading in performance and increased memory usage for large numbers of items (e.g more than 50).

The iCarouselDelegate protocol has the following optional methods:

	- (void)carouselWillBeginScrollingAnimation:(iCarousel *)carousel;
	
This method is called whenever the carousel will begin an animated scroll. This can be triggered programatically or automatically after the user finishes scrolling the carousel, as the carousel re-aligns itself.
	
	- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel;
	
This method is called when the carousel ends an animated scroll.
	
	- (void)carouselDidScroll:(iCarousel *)carousel;

This method is called whenever the carousel is scrolled. It is called regardless of whether the carousel was scrolled programatically or through user interaction.

	- (void)carouselCurrentItemIndexUpdated:(iCarousel *)carousel;

This method is called whenever the carousel scrolls far enough for the currentItemIndex property to change. It is called regardless of whether the item index was updated programatically or through user interaction.

	- (void)carouselWillBeginDragging:(iCarousel *)carousel;
	
This method is called when the user begins dragging the carousel. It will not fire if the user taps/clicks the carousel, or if the carousel is scrolled programmatically.
	
	- (void)carouselDidEndDragging:(iCarousel *)carousel willDecelerate:(BOOL)decelerate;
	
This method is called when the user stops dragging the carousel. The willDecelerate parameter indicates whether the carousel is travelling fast enough that it needs to decelerate before it stops (i.e. the current index is not necessarily the one it will stop at) or if it will stop where it is. Note that even if willDecelerate is NO, the carousel will still scroll automatically until it aligns exactly on the current index. If you need to know when it has stopped moving completely, use the carouselDidEndScrollingAnimation delegate method. On Mac OS, willDecelerate is always NO when using the scrollwheel because Mac OS implements its own inertia mechanism for scrolling.
	
	- (void)carouselWillBeginDecelerating:(iCarousel *)carousel;
	
This method is called when the carousel starts decelerating. it will typically be called immediately after the carouselDidEndDragging:willDecelerate: method, assuming willDecelerate was YES. On Mac OS, this method never fires when using the scrollwheel because Mac OS implements its own inertia mechanism for scrolling.
	
	- (void)carouselDidEndDecelerating:(iCarousel *)carousel;

This method is called when the carousel finishes decelerating and you can assume that the currentItemIndex at this point is the final stopping value. Unlike previous versions, the carousel will now stop exactly on the final index position in most cases. The only exception is on non-wrapped carousels with bounce enabled, where, if the final stopping position is beyond the end of the carousel, the carousel will then scroll automatically until it aligns exactly on the end index. For backwards compatibility, the carousel will always call `scrollToItemAtIndex:animated:` after it finishes decelerating. If you need to know for certain when the carousel has stopped moving completely, use the `carouselDidEndScrollingAnimation` delegate method.

	- (CGFloat)carouselItemWidth:(iCarousel *)carousel;

Returns the width of each item in the carousel - i.e. the spacing for each item view. If the method is not implemented, this defaults to the width of the first item view that is returned by the `carousel:viewForItemAtIndex:` dataSource method.

	- (CGFloat)carouseOffsetMultiplier:(iCarousel *)carousel;
	
Returns the offset multiplier to use when the user drags the carousel with their finger. It does not affect programmatic scrolling or deceleration speed. If the method is not implemented, this defaults to 1.0 for most carousel types, but defaults to 2.0 for the CoverFlow-style carousels to compensate for the fact that their items are more closely spaced and so must be dragged further to move the same distance.

	- (BOOL)carouselShouldWrap:(iCarousel *)carousel;

Return YES if you want the carousel to wrap around when it reaches the end, and no if you want it to stop. If you do not implement this method, wrapping will be enabled or disabled depending on the carousel type. Generally, circular carousel types will wrap by default and linear ones won't.

	- (CATransform3D)carousel:(iCarousel *)carousel transformForItemView:(UIView *)view withOffset:(CGFloat)offset;

This method can be used to provide a custom transform for each carousel view. The offset argument is the distance of the view from the middle of the carousel. The  currently centered item view would have an offset of 0, the one to the right would have an offset value of 1.0, the one to the left an offset value of -1.0, and so on. To implement the linear carousel style, you would therefore simply multiply the offset value by the item width and use it as the x value of the transform. If you need to manipulate the view in other ways as it scrolls, such as settings its alpha opacity, you can manipulate the view property directly. Manipulating the view frame, center or bounds is not recommended as the effect may be unpredictable and subject to undocumented change in future releases.

	- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index;

This method will fire if the user taps any carousel item view (not including placeholder views), including the currently selected view. This method will not fire if the user taps a control within the currently selected view (i.e. any view that is a subclass of UIControl). **This method is currently only supported on the iOS version of iCarousel.**

	- (BOOL)carousel:(iCarousel *)carousel shouldSelectItemAtIndex:(NSInteger)index;
	
This method will fire if the user taps any carousel item view (not including placeholder views), including the currently selected view. The purpose of a method is to give you the opportunity to ignore a tap on the carousel. If you return YES from the method, or don't implement it, the tap will be processed as normal and the `carousel:didSelectItemAtIndex:` method will be called. If you return NO, the carousel will ignore the tap and it will continue to propagate up the view hierarchy. This is a good way to prevent the carousel intercepting tap events intended for processing by another view. **This method is currently only supported on the iOS version of iCarousel.**


Detecting Taps on Item Views
----------------------------

There are two basic approaches to detecting taps on views in iCarousel on iOS. The first approach is to simply use the `carousel:didSelectItemAtIndex:` delegate method, which fires every time an item is tapped. If you are only interested in taps on the currently centered item, you can compare the `currentItemIndex` property against the index parameter of this method.

Alternatively, if you want a little more control you can supply a UIButton or UIControl as the item view and handle the touch interactions yourself. See the Events test projects for an example of how this is done (doesn't work on Mac OS; see below).

You can also nest UIControls within your item views and these will receive touches as expected (see the Controls test project for an example).

If you wish to detect other types of interaction such as swipes, double taps or long presses, the simplest way is to attach a UIGestureRecognizer to your item view or its subviews before passing it to the carousel.

Note that taps and gestures will be ignored on any item view except the currently selected one, unless you set the `centerItemWhenSelected` property to NO.

On Mac OS there is no easy way to detect clicks on carousel items currently. You cannot just supply an NSButton as or inside your item view because the transforms applied to the item views mean that hit detection doesn't work properly. I'm investigating possible solutions to this (if you know a good way to fix this, please get in touch, or fork the project on github).
