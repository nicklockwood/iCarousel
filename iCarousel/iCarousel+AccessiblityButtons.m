//
//  iCarousel+AccessiblityButtons.m
//  CardCompanion
//
//  Created by Wang, Jinlian(Sunny) on 5/29/15.
//

#import <objc/runtime.h>
#import "iCarousel+AccessiblityButtons.h"
#import "iCarousel.h"

#define BUTTON_WIDTH 50

@interface iCarousel (accessibilityAuxiliaryViews)

@end

@implementation iCarousel (AccessiblityButtons)
@dynamic auxiliaryButtons;

-(BOOL)isAccessibilityElement{
    return NO;
}

-(void)setUpAccessiblity{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voiceOverChanged:) name:UIAccessibilityVoiceOverStatusChanged object:nil];
    [self handleVoiceOverStatusChange];
}

-(void)cleanUpAccessibility{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIAccessibilityVoiceOverStatusChanged object:nil];
}

-(void)voiceOverChanged:(NSNotification *)notification {
    [self handleVoiceOverStatusChange];
}

-(void)handleVoiceOverStatusChange{
    if(UIAccessibilityIsVoiceOverRunning() && !self.auxiliaryButtons){
        [self setupAuxiliaryButtons];
    }
    
    NSArray *array = (NSArray *)self.auxiliaryButtons;
    [array enumerateObjectsUsingBlock:^(UIView *button, NSUInteger index, BOOL *stop){
        button.hidden = !UIAccessibilityIsVoiceOverRunning();
    }];
}


- (void)setAuxiliaryButtons:(id)array {
    objc_setAssociatedObject(self, @selector(auxiliaryButtons), array, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)auxiliaryButtons {
    return objc_getAssociatedObject(self, @selector(auxiliaryButtons));
}

-(void)setupAuxiliaryButtons{
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:2];
    UIButton *forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    forwardButton.accessibilityLabel = @"Scroll Forward";
    [forwardButton setTitle: @"\u2329" forState: UIControlStateNormal];
    forwardButton.accessibilityTraits = forwardButton.accessibilityTraits | UIAccessibilityTraitStartsMediaSession;
    forwardButton.backgroundColor = [UIColor colorWithWhite:0.7f alpha:0.7];
    [forwardButton addTarget:self action:@selector(forwardButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:forwardButton];
    forwardButton.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(forwardButton);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[forwardButton]-0-|" options:0 metrics:nil views:viewsDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[forwardButton(50)]" options:0 metrics:nil views:viewsDictionary]];
    [array addObject:forwardButton];
    
    UIButton *backwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backwardButton.accessibilityLabel = @"Scroll Backward";
    backwardButton.accessibilityTraits = backwardButton.accessibilityTraits | UIAccessibilityTraitStartsMediaSession;
    [backwardButton setTitle: @"\u232a" forState: UIControlStateNormal];
    backwardButton.backgroundColor = [UIColor colorWithWhite:0.7f alpha:0.7];
    [backwardButton addTarget:self action:@selector(backwardButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:backwardButton];
    backwardButton.translatesAutoresizingMaskIntoConstraints = NO;
    viewsDictionary = NSDictionaryOfVariableBindings(backwardButton);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[backwardButton]-0-|" options:0 metrics:nil views:viewsDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[backwardButton(50)]-0-|" options:0 metrics:nil views:viewsDictionary]];
    [array addObject:backwardButton];
    
    self.auxiliaryButtons = array;
}

-(void)forwardButtonTapped:(id)sender{
    if(self.currentItemIndex > 0){
        [self scrollToItemAtIndex:(self.currentItemIndex-1) animated:YES completionHandler:^(NSInteger index){
            NSString *announcement = [self accessibilityAnnouncement:index isForwarded:YES];
            UIAccessibilityPostNotification(UIAccessibilityPageScrolledNotification, announcement);
        }];
    }
}

-(void)backwardButtonTapped:(id)sender{
    if(self.currentItemIndex < (self.numberOfItems -1)){
        [self scrollToItemAtIndex:(self.currentItemIndex+1) animated:YES completionHandler:^(NSInteger index){
            NSString *announcement = [self accessibilityAnnouncement:index isForwarded:NO];
            UIAccessibilityPostNotification(UIAccessibilityPageScrolledNotification,announcement);
        }];
    }
}

-(NSString *)accessibilityAnnouncement:(NSInteger)index isForwarded:(BOOL)forwarded{
    NSString *announcement = nil;
    if([self.delegate respondsToSelector:@selector(accessibilityAnnoucement:isForwarded:)]){
        announcement = [self.delegate accessibilityAnnoucement:index isForwarded:forwarded];
    }
    announcement = announcement ? announcement: [NSString stringWithFormat:@"Item %ld", (long) index];
    return announcement;
}

@end
