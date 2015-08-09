//
//  iCarousel+Accessibility.m
//  CardCompanion
//
//  Created by Wang, Jinlian(Sunny) on 5/29/15.
//

#import "iCarousel+AccessibilityScrolling.h"

@implementation iCarousel (AccessibilityScrolling)

- (void)setUpAccessiblity{
    //Need UIAccessibilityTraitCausesPageTurn flag to announce hint if iCarousel is made to be accessibible
    self.accessibilityTraits = self.accessibilityTraits | UIAccessibilityTraitCausesPageTurn;
}

-(BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction{
    BOOL result = YES;
    switch (direction) {
        case UIAccessibilityScrollDirectionNext:
        case UIAccessibilityScrollDirectionRight:
            if(self.currentItemIndex > 0){
                [self scrollToItemAtIndex:(self.currentItemIndex-1) animated:YES completionHandler:^(NSInteger index){
                    NSString *announcement = [self accessibilityAnnouncement:index isForwarded:NO];
                    UIAccessibilityPostNotification(UIAccessibilityPageScrolledNotification, announcement);
                }];
            } else {
                result = NO;
            }
            break;
        case UIAccessibilityScrollDirectionPrevious:
        case UIAccessibilityScrollDirectionLeft:
            if(self.currentItemIndex < (self.numberOfItems-1)){
                [self scrollToItemAtIndex:(self.currentItemIndex+1) animated:YES completionHandler:^(NSInteger index){
                    NSString *announcement = [self accessibilityAnnouncement:index isForwarded:YES];
                    UIAccessibilityPostNotification(UIAccessibilityPageScrolledNotification, announcement);
                }];
            } else {
                result = NO;
            }
            break;
        case UIAccessibilityScrollDirectionUp:
        case UIAccessibilityScrollDirectionDown:
            result = NO;
            break;
    }
    return result;
}

-(NSString *)accessibilityAnnouncement:(NSInteger)index isForwarded:(BOOL)forwarded{
    NSString *announcement = nil;
    __strong id<iCarouselDelegate> delegate = self.delegate;
    if([delegate respondsToSelector:@selector(accessibilityAnnoucement:isForwarded:)]){
        announcement = [delegate accessibilityAnnoucement:index isForwarded:forwarded];
    }
    announcement = announcement ? announcement: [NSString stringWithFormat:@"Item %ld", (long) index];
    return announcement;
}

@end
