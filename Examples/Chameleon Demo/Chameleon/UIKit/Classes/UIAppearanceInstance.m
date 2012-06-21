/*
 * Copyright (c) 2012, The Iconfactory. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of The Iconfactory nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "UIAppearanceInstance.h"
#import "UIAppearanceProperty.h"
#import "UIAppearanceProxy.h"
#import <objc/runtime.h>

static const char *UIAppearanceClassAssociatedObjectKey = "UIAppearanceClassAssociatedObjectKey";
static const char *UIAppearanceInstanceAssociatedObjectKey = "UIAppearanceInstanceAssociatedObjectKey";

static NSString * const UIAppearanceInstancePropertiesKey = @"UIAppearanceInstancePropertiesKey";
static NSString * const UIAppearanceInstanceNeedsUpdateKey = @"UIAppearanceInstanceNeedsUpdateKey";

static NSMutableDictionary *UIAppearanceInstanceDictionary(id object)
{
    return objc_getAssociatedObject(object, UIAppearanceInstanceAssociatedObjectKey);
}

static NSMutableDictionary *UIAppearanceInstanceDictionaryCreateIfNeeded(id object)
{
    NSMutableDictionary *info = UIAppearanceInstanceDictionary(object);
    
    if (!info) {
        info = [NSMutableDictionary dictionaryWithCapacity:1];
        objc_setAssociatedObject(object, UIAppearanceInstanceAssociatedObjectKey, info, OBJC_ASSOCIATION_RETAIN);
    }
    
    return info;
}

static void UIAppearanceInstanceSetProperties(id object, NSSet *properties)
{
    if ([properties count] > 0) {
        [UIAppearanceInstanceDictionaryCreateIfNeeded(object) setObject:properties forKey:UIAppearanceInstancePropertiesKey];
    } else {
        [UIAppearanceInstanceDictionary(object) removeObjectForKey:UIAppearanceInstancePropertiesKey];
    }
}

static NSSet *UIAppearanceInstanceProperties(id object)
{
    return [UIAppearanceInstanceDictionary(object) objectForKey:UIAppearanceInstancePropertiesKey];
}

static void UIAppearanceInstancePropertyDidChange(id object, UIAppearanceProperty *property)
{
    UIAppearanceInstanceSetProperties(object, [[NSSet setWithObject:property] setByAddingObjectsFromSet:UIAppearanceInstanceProperties(object)]);
}

static BOOL UIAppearanceInstanceNeedsUpdate(id object)
{
    return [[UIAppearanceInstanceDictionary(object) objectForKey:UIAppearanceInstanceNeedsUpdateKey] boolValue];
}

static void UIAppearanceInstanceSetNeedsUpdate(id object, BOOL needsUpdate)
{
    [UIAppearanceInstanceDictionaryCreateIfNeeded(object) setObject:[NSNumber numberWithBool:needsUpdate] forKey:UIAppearanceInstanceNeedsUpdateKey];
}

static NSArray *UIAppearanceHierarchyForClass(Class klass)
{
    NSMutableArray *classes = [[NSMutableArray alloc] initWithCapacity:0];

    while ([(id)klass conformsToProtocol:@protocol(UIAppearance)]) {
        [classes insertObject:klass atIndex:0];
        klass = [klass superclass];
    }
    
    return [classes autorelease];
}

@implementation NSObject (UIAppearanceInstance)

+ (id)appearance
{
    return [self appearanceWhenContainedIn:nil];
}

+ (id)appearanceWhenContainedIn:(Class <UIAppearanceContainer>)containerClass, ...
{
    NSMutableDictionary *appearanceRules = objc_getAssociatedObject(self, UIAppearanceClassAssociatedObjectKey);
    
    if (!appearanceRules) {
        appearanceRules = [NSMutableDictionary dictionaryWithCapacity:1];
        objc_setAssociatedObject(self, UIAppearanceClassAssociatedObjectKey, appearanceRules, OBJC_ASSOCIATION_RETAIN);
    }
    
    NSMutableArray *containmentPath = [NSMutableArray arrayWithCapacity:1];
    
    va_list args;
    va_start(args, containerClass);
    for (; containerClass != nil; containerClass = va_arg(args, Class <UIAppearanceContainer>)) {
        [containmentPath addObject:containerClass];
    }
    va_end(args);
    
    UIAppearanceProxy *record = [appearanceRules objectForKey:containmentPath];
    
    if (!record) {
        record = [[[UIAppearanceProxy alloc] initWithClass:self] autorelease];
        [appearanceRules setObject:record forKey:containmentPath];
    }
    
    return record;
}

- (void)_appearancePropertyDidChange:(UIAppearanceProperty *)property
{
    UIAppearanceInstancePropertyDidChange(self, property);
}

- (id)_appearanceContainer
{
    return nil;
}

- (void)_updateAppearanceIfNeeded
{
    if (UIAppearanceInstanceNeedsUpdate(self)) {
        // first go down our own class heirarchy until we find the root of the UIAppearance protocol
        // then we'll start at the bottom and work up while checking each class for all relevant rules
        // that apply to this instance at this time.
        
        NSArray *classes = UIAppearanceHierarchyForClass([self class]);
        NSMutableDictionary *propertiesToSet = [NSMutableDictionary dictionaryWithCapacity:0];
        
        for (Class klass in classes) {
            NSMutableDictionary *rules = objc_getAssociatedObject(klass, UIAppearanceClassAssociatedObjectKey);
            
            // sorts the rule keys (which are arrays of classes) by length
            // if the lengths match, it sorts based on the last class being a superclass of the other or vice-versa
            // if the last classes aren't related at all, it marks them equal (I suspect these cases will always be filtered out in the next step)
            NSArray *sortedRulePaths = [[rules allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSArray *path1, NSArray *path2) {
                if ([path1 count] == [path2 count]) {
                    if ([[path2 lastObject] isKindOfClass:[path1 lastObject]]) {
                        return (NSComparisonResult)NSOrderedAscending;
                    } else if ([[path1 lastObject] isKindOfClass:[path2 lastObject]]) {
                        return (NSComparisonResult)NSOrderedDescending;
                    } else {
                        return (NSComparisonResult)NSOrderedSame;
                    }
                } else if ([path1 count] < [path2 count]) {
                    return (NSComparisonResult)NSOrderedAscending;
                } else {
                    return (NSComparisonResult)NSOrderedDescending;
                }
            }];
            
            // we should now have a list of classes to check for rule settings for this instance, so now we spin
            // through those and fetch the properties and values and add them to the dictionary of things to do.
            // before applying a rule's properties, we must make sure this instance is qualified, so we must check
            // this instance's container hierarchy against ever class that makes up the rule.
            for (NSArray *rule in sortedRulePaths) {
                BOOL shouldApplyRule = YES;
                
                for (Class klass in [rule reverseObjectEnumerator]) {
                    id container = [self _appearanceContainer];

                    while (container && ![container isKindOfClass:klass]) {
                        container = [container _appearanceContainer];
                    }
                    
                    if (!container) {
                        shouldApplyRule = NO;
                        break;
                    }
                }
                
                if (shouldApplyRule) {
                    UIAppearanceProxy *proxy = [rules objectForKey:rule];
                    [propertiesToSet addEntriesFromDictionary:[proxy _appearancePropertiesAndValues]];
                }
            }
        }
        
        // before setting the actual properties on the instance, save off a copy of the existing modified properties
        // because the act of setting the UIAppearance properties will end up messing with that set.
        // after we're done actually applying everything, reset the modified properties set to what it was before.
        NSSet *originalProperties = [UIAppearanceInstanceProperties(self) copy];
        
        // subtract any properties that have been overriden from the list to apply
        [propertiesToSet removeObjectsForKeys:[originalProperties allObjects]];
        
        // now apply everything that's left
        [propertiesToSet enumerateKeysAndObjectsUsingBlock:^(UIAppearanceProperty *property, NSValue *value, BOOL *stop) {
            [property invokeSetterUsingTarget:self withValue:value];
        }];
        
        // now reset our set of changes properties to the original set so we don't count the UIAppearance defaults
        UIAppearanceInstanceSetProperties(self, originalProperties);
        [originalProperties release];
        
        // done!
        UIAppearanceInstanceSetNeedsUpdate(self, NO);
    }
}

- (void)_setAppearanceNeedsUpdate
{
    UIAppearanceInstanceSetNeedsUpdate(self, YES);
}

@end
