Purpose
--------------

iCarousel is a class designed to simplify the implementation of various types of carousel (paged, scrolling views) on iPhone and iPad. iCarousel implements a number of common effects such as cylindrical, flat and "CoverFlow" style carousels, as well as providing hooks to implement your own bespoke effects. Unlike many other "CoverFlow" libraries, iCarousel can work with any kind of view, not just images, so it is ideal for presenting paged data in a fluid and impressive way in your app. It also makes it extremely easy to swap between different carousel effects with minimal code changes.


Installation
--------------

To use the iCarousel class in an app, just drag the class files into your project and add the QuartzCore framework.


Carousel Types
--------------

iCarousel supports the following built-in display types:

iCarouselTypeLinear
iCarouselTypeRotary
iCarouselTypeInvertedRotary
iCarouselTypeCylinder
iCarouselTypeInvertedCylinder
iCarouselTypeCoverFlow

You can also implement your own bespoke style using iCarouselTypeCustom and the carousel:transformForItemView:withOffset: delegate method.


Properties
--------------

The iCarousel has the following properties:

@property (nonatomic, assign) IBOutlet id<iCarouselDataSource> dataSource;

An object that supports the iCarouselDataSource protocol and can provide views to populate the carousel.

@property (nonatomic, assign) IBOutlet id<iCarouselDelegate> delegate;

An object that supports the iCarouselDelegate protocol and can respond to carousel events and layout requests.

@property (nonatomic, assign) iCarouselType type;

Used to switch the carousel display types (see above for details).

@property (nonatomic, assign) float perspective;

Used to tweak the perspective foreshortening effect for the various 3D carousel views. Should be a negative value, less than 0 and greater than -0.01. Values outside of this range will yield very strange results. The default is -1/500, or -0.005;

@property (nonatomic, assign) float decelerationRate;

The rate at which the carousel decelerates when flicked. The default value is 0.9, values should be in the range 0.0 (carousel stops instantly when released) to 1 .0 (carousel continues indefinitely until it reaches the end).

@property (nonatomic, assign) BOOL bounces;

Sets whether the carousel should bounce past the end and return, or stop dead. Note that this has no effect on carousel types that are designed to wrap, or where the carouselShouldWrap delegate method returns YES.

@property (nonatomic, assign) BOOL scrollEnabled;

Enables and disables user scrolling of the carousel. The carousel can still be scrolled programmatically if this property is set to NO.

@property (nonatomic, readonly) NSInteger numberOfItems;

The number of items currently displayed in the carousel (read only).

@property (nonatomic, readonly) NSArray *itemViews;

An array of the item views currently displayed in the carousel (read only).

@property (nonatomic, readonly) NSInteger currentItemIndex;

The currently centered item in the carousel (read only).

@property (nonatomic, readonly) float itemWidth;

The display width of items in the carousel (read only).

@property (nonatomic, readonly) UIPageControl * pageControl;

The UIPageControl which shows this carousel pages count and current page. Its hidden value should be changed to NO if you want it to show (read only).


Methods
--------------

The iCarousel class has the following methods:

- (void)scrollToItemAtIndex:(NSUInteger)index animated:(BOOL)animated;

This will center the carousel on the specified item;

- (void)removeItemAtIndex:(NSUInteger)index animated:(BOOL)animated;

This removes an item from the carousel. The remaining items will slide across to fill the gap. Note that the data source is not updated when this method is called, so a subsequent call to reloadData will restore the removed item.

- (void)insertItemAtIndex:(NSUInteger)index animated:(BOOL)animated;

This inserts an item into the carousel. The new item will be requested from the dataSource, so make sure that the new item has been added to the data source data before calling this method, or you will get duplicate items in the carousel, or other weirdness.

- (void)reloadData;

This reloads all carousel views from the dataSource and refreshes the carousel display.


Protocols
---------------

The iCarousel follows the Apple convention for data-driven views by providing two protocol interfaces, iCarouselDataSource and iCarouselDelegate. The iCarouselDataSource protocol has the following mandatory methods:

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel;

Return the number of items (views) in the carousel.

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index;

Return a view to be displayed at the specified index in the carousel. Unlike UITableView, there is no dequeuing system for iCarousel item views, but you should ensure that each time the carousel:viewForPageAtIndex: method is called, it returns a new view instance, as returning multiple copies of the same view may cause display issues with the carousel.

The iCarouselDataSource protocol has the following optional methods:

- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel;

Returns the number of placeholder views to display in the carousel. Placeholder views are intended to be used when the number of items in the carousel is too few to fill the carousel width, and you wish to display something in the empty space. They move with the carousel and behave just like any other carousel item, but they do not count towards the numberOfItems value, and cannot be set as the currently selected item. Note that the placeholders are mirrored on either side of the carousel, so if you only need one placeholder on either side of the real items, return a value of 1, not 2. Also, note that placeholder views cannot be used with a wrapped carousel type. 

- (UIView *)carouselPlaceholderView:(iCarousel *)carousel;

Return a view to be displayed as the placeholder view. Placeholder views should be identical as they may be displayed in any order, however, as with the regular item views, you must return a unique view instance for each call to carouselPlaceholderView: to avoid display issues.

The iCarouselDelegate protocol has the following optional methods:

- (void)carouselDidScroll:(iCarousel *)carousel;

This method is called whenever the carousel is scrolled. It is called regardless of whether the carousel was scrolled programatically or through user interaction.

- (void)carouselCurrentItemIndexUpdated:(iCarousel *)carousel;

This method is called whenever the carousel scrolls far enough for the currentItemIndex property to change. It is called regardless of whether the item index was updated programatically or through user interaction.

- (float)carouselItemWidth:(iCarousel *)carousel;

Returns the width of each item in the carousel - i.e. the spacing for each item view. If the method is not implemented, this defaults to the width of the first item view that is returned by the carousel:viewForItemAtIndex: method.

- (BOOL)carouselShouldWrap:(iCarousel *)carousel;

Return YES if you want the carousel to wrap around when it reaches the end, and no if you want it to stop. If you do not implement this method, wrapping will be enabled or disabled depending on the carousel type. Generally, circular carousel types will wrap by default and linear ones won't.

- (CATransform3D)carousel:(iCarousel *)carousel transformForItemView:(UIView *)view withOffset:(float)offset;

This method can be used to provide a custom transform for each carousel view. The offset argument is the distance of the view from the middle of the carousel. The  currently centered item view would have an offset of 0, the one to the right would have an offset value of 1.0, the one to the left an offset value of -1.0, and so on. To implement the linear carousel style, you would therefore simply multiply the offset value by the item width and use it as the x value of the transform. If you need to manipulate the view in other ways as it scrolls, such as settings its alpha opacity, you can manipulate the view property directly. Manipulating the view frame, center or bounds is not recommended as the effect may be unpredictable and subject to undocumented change in future releases.