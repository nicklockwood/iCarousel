Purpose
--------------

iCarousel is a class designed to simplify the implementation of various types of carousel (paged, scrolling views) on iPhone and iPad. iCarousel implements a number of common effects such as cylindrical, flat and "CoverFlow" style carousels, as well as providing hooks to implement your own bespoke effects. Unlike other   "CoverFlow" libraries, iCarousel can work with any kind of view, not just images, so it is ideal for presenting paged data in a fluid and impressive way in your app.


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

@property (nonatomic, readonly) NSInteger numberOfItems;

The number of items currently displayed in the carousel (read only).

@property (nonatomic, readonly) NSInteger currentItemIndex;

The currently centered item in the carousel (read only).

@property (nonatomic, readonly) float itemWidth;

The display width of items in the carousel (read only).


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

The iCarouselDelegate protocol has the following optional methods:

- (void)carouselDidScroll:(iCarousel *)carousel;

This method is called whenever the carousel is scrolled. It is called regardless of whether the carousel was scrolled programatically or through user interaction.

- (void)carouselCurrentItemIndexUpdated:(iCarousel *)carousel;

This method is called whenever the carousel scrolls far enough for the currentItemIndex property to change. It is called regardless of whether the item index was updated programatically or through user interaction.

- (float)carouselItemWidth:(iCarousel *)carousel;

Returns the width of each item in the carousel - i.e. the spacing for each item view This defaults to the width of the carousel component, meaning that only one item will be visible at a time.

- (BOOL)carouselShouldWrap:(iCarousel *)carousel;

Return YES if you want the carousel to wrap around when it reaches the end, and no if you want it to stop. If you do not implement this method, wrapping will be enabled or disabled depending on the carousel type. Generally, circular carousel types will wrap by default and linear ones won't.

- (CATransform3D)carousel:(iCarousel *)carousel transformForItemView:(UIView *)view withOffset:(float)offset;

This method can be used to provide a custom transform for each carousel view. The offset argument is the distance of the view from the middle of the carousel. The  currently centered item view would have an offset of 0, the one to the right would have an offset value of 1.0, the one to the left an offset value of -1.0, and so on. To implement the linear carousel style, you would therefore simply multiply the offset value by the item width and use it as the x value of the transform. If you need to manipulate the view in other ways as it scrolls, such as settings its alpha opacity, you can manipulate the view property directly. You should not manipulate the view.layer.transform property however, as this will be overwritten by the return value. Also, manipulating the view frame, center or bounds is not recommended as the effect may be unpredictable and subject to undocumented change in future releases.