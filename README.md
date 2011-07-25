Purpose
--------------

iCarousel is a class designed to simplify the implementation of various types of carousel (paged, scrolling views) on iPhone, iPad and Mac OS. iCarousel implements a number of common effects such as cylindrical, flat and "CoverFlow" style carousels, as well as providing hooks to implement your own bespoke effects. Unlike many other "CoverFlow" libraries, iCarousel can work with any kind of view, not just images, so it is ideal for presenting paged data in a fluid and impressive way in your app. It also makes it extremely easy to swap between different carousel effects with minimal code changes.

*Special thanks go to Sushant Prakash (https://github.com/sushftw) for the Mac port.*

Not all features of iCarousel are currently supported on Mac OS. I hope to address this in future. Please refer to the documentation below for details.


Installation
--------------

To use the iCarousel class in an app, just drag the class files into your project and add the QuartzCore framework.


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

You can also implement your own bespoke style using `iCarouselTypeCustom` and the `carousel:transformForItemView:withOffset:` delegate method.


Properties
--------------

The iCarousel has the following properties (note: for Mac OS, substitute NSView for UIView when using properties):

	@property (nonatomic, assign) IBOutlet id<iCarouselDataSource> dataSource;

An object that supports the iCarouselDataSource protocol and can provide views to populate the carousel.

	@property (nonatomic, assign) IBOutlet id<iCarouselDelegate> delegate;

An object that supports the iCarouselDelegate protocol and can respond to carousel events and layout requests.

	@property (nonatomic, assign) iCarouselType type;

Used to switch the carousel display type (see above for details).

	@property (nonatomic, assign) float perspective;

Used to tweak the perspective foreshortening effect for the various 3D carousel views. Should be a negative value, less than 0 and greater than -0.01. Values outside of this range will yield very strange results. The default is -1/500, or -0.005;

	@property (nonatomic, assign) CGSize contentOffset;

This property is used to adjust the offset of the carousel item views relative to the center of the carousel. It defaults to CGSizeZero, meaning that the carousel items are centered. Changing this value moves both the carousel items without changing their perspective, i.e. the vanishing point moves with the carousel items, so if you move the carousel items down, it *does not* appear as if you are looking down on the carousel.

	@property (nonatomic, assign) CGSize viewpointOffset;

This property is used to adjust the user viewpoint relative to the carousel items. It has the opposite effect to adjusting the contentOffset, i.e. if you move the viewpoint up then the carousel appears to move down. Unlike the contentOffset, moving the viewpoint also changes the perspective vanishing point relative to the carousel items, so if you move the viewpoint up, it will appear as if you are looking down on the carousel.

Note that the viewpointOffset transform is concatenated with the carousel item transform used by the carousel (or the custom transform you have supplied using the transformForItemView delegate method), so if the carousel items are rotated or scaled then this may not have the desired effect.

	@property (nonatomic, assign) float decelerationRate;

The rate at which the carousel decelerates when flicked. Higher values mean slower deceleration. The default value is 0.95. Values should be in the range 0.0 (carousel stops immediately when released) to 1.0 (carousel continues indefinitely without slowing down, unless it reaches the end).

	@property (nonatomic, assign) BOOL bounces;

Sets whether the carousel should bounce past the end and return, or stop dead. Note that this has no effect on carousel types that are designed to wrap, or where the carouselShouldWrap delegate method returns YES.

	@property (nonatomic, assign) BOOL scrollEnabled;

Enables and disables user scrolling of the carousel. The carousel can still be scrolled programmatically if this property is set to NO.

	@property (nonatomic, readonly) NSInteger numberOfItems;

The number of items currently displayed in the carousel (read only). To set this, implement the `numberOfItemsInCarousel:` dataSource method.

	@property (nonatomic, readonly) NSSet *visibleViews;

A set of all the item views currently displayed in the carousel (read only). The order of these views is arbitrary, and does not relate to the item indices.

	@property (nonatomic, readonly) UIView *contentView;

The view containing the carousel item views. You can add subviews to this view if you want to intersperse a view with the carousel items. If you want a view to appear in front or behind the carousel items, you should add it directly to the iCarousel view itself instead. Note that the order of views inside the contentView is subject to frequent and undocumented change while the app is running. Any views added to the contentView should have their userInteractionEnabled property set to NO to prevent conflicts with iCarousel's touch event handling.

	@property (nonatomic, readonly) NSInteger currentItemIndex;

The currently centered item in the carousel (read only). To change this, use the `scrollToItemAtIndex:` methods. 

	@property (nonatomic, readonly) float itemWidth;

The display width of items in the carousel (read only). This is derived automatically from the first view passed in to the carousel using the `carousel:viewForItemAtIndex:` dataSource method. You can also override this value using the `carouselItemWidth:` delegate method, which will alter the spacing between carousel items.

	@property (nonatomic, assign) BOOL centerItemWhenSelected;

When set to YES, tapping any item in the carousel other than the one matching the currentItemIndex will cause it to smoothly animate to the center. Tapping the currently selected item will have no effect. **This property is currently only supported on the iOS version of iCarousel.**

	@property (nonatomic, assign) NSInteger numberOfVisibleItems;
	
This is the maximum number of item views that should be visible in the carousel at once. Half of this number of views will be displayed to either side of the currently selected item index. Views beyond that will not be loaded until they are scrolled into view. This allows for the carousel to contain a very large number of items without adversely affecting performance. The numberOfVisibleItems should be a positive odd number, and defaults to 21.

	@property (nonatomic, readonly) float scrollSpeed;
	
This is the scroll speed multiplier when the user drags the carousel with their finger (read only). By default this is 1.0 for most carousel types, but defaults to 4.0 for the CoverFlow-style carousels to compensate for the fact that their items are more closely spaced. To change the default scrollSpeed, implement the `carouselScrollSpeed:` delegate method.

	@property (nonatomic, readonly) float toggle;
	
This property is used for the `iCarouselTypeCoverFlow2` carousel transform. It is exposed so that you can implement your own variants of the CoverFlow2 style using the `carousel:transformForItemView:withOffset` delegate method.


Methods
--------------

The iCarousel class has the following methods (note: for Mac OS, substitute NSView for UIView in method arguments):

	- (void)scrollToItemAtIndex:(NSUInteger)index animated:(BOOL)animated;

This will center the carousel on the specified item, either immediately or with a smooth animation. For wrapped carousels, the carousel will automatically determine the shortest (direct, or wraparound) distance to scroll. If you need to control the scroll direction, use the scrollByNumberOfItems method instead.

	- (void)scrollToItemAtIndex:(NSUInteger)index duration:(NSTimeInterval)scrollDuration;

This method allows you to control how long the carousel takes to scroll to the specified index.

	- (void)scrollByNumberOfItems:(NSInteger)itemCount duration:(NSTimeInterval)duration;

This method allows you to scroll the carousel by a fixed distance, measured in carousel item widths. Positive or negative values may be specified for itemCount, depending on the direction you wish to scroll, and iCarousel gracefully handles bounds issues, so if you specify a distance greater than the number of items in the carousel, scrolling will either be clamped when it reaches the end of the carousel (if wrapping is disabled) or wrap around seamlessly.

	- (void)reloadData;

This reloads all carousel views from the dataSource and refreshes the carousel display.

	- (void)removeItemAtIndex:(NSUInteger)index animated:(BOOL)animated;

This removes an item from the carousel. The remaining items will slide across to fill the gap. Note that the data source is not updated when this method is called, so a subsequent call to reloadData will restore the removed item.

	- (void)insertItemAtIndex:(NSUInteger)index animated:(BOOL)animated;

This inserts an item into the carousel. The new item will be requested from the dataSource, so make sure that the new item has been added to the data source data before calling this method, or you will get duplicate items in the carousel, or other weirdness.


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

	- (float)carouselItemWidth:(iCarousel *)carousel;

Returns the width of each item in the carousel - i.e. the spacing for each item view. If the method is not implemented, this defaults to the width of the first item view that is returned by the `carousel:viewForItemAtIndex:` dataSource method.

	- (float)carouseScrollSpeed:(iCarousel *)carousel;
	
Returns the scroll speed multiplier when the user drags the carousel with their finger. It does not affect programmatic scrolling or deceleration speed. If the method is not implemented, this defaults to 1.0 for most carousel types, but defaults to 4.0 for the CoverFlow-style carousels to compensate for the fact that their items are more closely spaced.

	- (BOOL)carouselShouldWrap:(iCarousel *)carousel;

Return YES if you want the carousel to wrap around when it reaches the end, and no if you want it to stop. If you do not implement this method, wrapping will be enabled or disabled depending on the carousel type. Generally, circular carousel types will wrap by default and linear ones won't.

	- (CATransform3D)carousel:(iCarousel *)carousel transformForItemView:(UIView *)view withOffset:(float)offset;

This method can be used to provide a custom transform for each carousel view. The offset argument is the distance of the view from the middle of the carousel. The  currently centered item view would have an offset of 0, the one to the right would have an offset value of 1.0, the one to the left an offset value of -1.0, and so on. To implement the linear carousel style, you would therefore simply multiply the offset value by the item width and use it as the x value of the transform. If you need to manipulate the view in other ways as it scrolls, such as settings its alpha opacity, you can manipulate the view property directly. Manipulating the view frame, center or bounds is not recommended as the effect may be unpredictable and subject to undocumented change in future releases.

	- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index;

This method will fire if the user taps any carousel item view (not including placeholder views), including the currently selected view. This method will not fire if the user taps a control within the currently selected view (i.e. any view that is a subclass of UIControl). **This method is currently only supported on the iOS version of iCarousel.**


Detecting Taps on Item Views
----------------------------

There are two basic approaches to detecting taps on views in iCarousel on iOS. The first approach is to simply use the `carousel:didSelectItemAtIndex:` delegate method, which fires every time an item is tapped. If you are only interested in taps on the currently centered item, you can compare the `currentItemIndex` property against the index parameter of this method.

Alternatively, if you want a little more control can supply a UIButton or UIControl as the item view and handle the touch interactions yourself. See the iOS example project for a demo of how this is done (doesn't work on Mac OS, see below).

You can also nest UIControls within your item views and these will receive touches as expected.

If you wish to detect other types of interaction such as swipes, double taps or long presses, the simplest way is to attach a UIGestureRecognizer to your item view or its subviews before passing it to the carousel.

Note that taps and gestures will be ignored on any item view except the currently selected one, unless you set the `centerItemWhenSelected` property to NO.

On Mac OS there is no easy way to do detect clicks on carousel items currently. You cannot just supply an NSButton as your item view because the transforms applied to the item views mean that hit detection doesn't work properly. I'm investigating possible solutions to this (if you know a good way to fix this, please get in touch, or fork the project on github).