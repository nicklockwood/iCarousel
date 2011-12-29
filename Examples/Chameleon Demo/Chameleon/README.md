# Chameleon

Chameleon is a port of Apple's UIKit (and some minimal related frameworks) to Mac OS X. It is meant to be as much of a drop-in replacement for the real UIKit as possible. It also adapts some iOS user interface conventions to the Mac (such as UIAlertView being represented by NSAlert) so that apps built using Chameleon have as much chance as possible of feeling at home on the desktop with relatively little porting effort.

Chameleon requires OS X 10.6 or higher. Apps built with it have been proven to be acceptable to Apple for the Mac App Store. Chameleon was first built by [The Iconfactory](http://iconfactory.com/) to unify the codebase of [Twitterrific](http://www.twitterrific.com/) for both Mac and iOS.

The UIKit implementation mostly targets iOS 3.2's version of UIKit. Not everything is implemented at this time, but a surprisingly large subset is. There are some methods and/or behaviors from later versions of iOS implemented as well. Any UIKit methods that were deprecated around iOS 3.2 are not included.

As a general rule, if Apple's UIKit behaves in a certain way for some piece of code, that behavior should be considered correct even if you don't like how Apple's version does things. If Chameleon's behavior differs, Chameleon is wrong. That said, before immediately blaming problems on Chameleon, be absolutely sure that your code is, in fact, behaving differently than it would on Apple's implementation. Also be certain that there isn't a good reason Chameleon's behavior may differ. (An example of a difference that is intended is the behavior of UIAlertView - in Apple's UIKit, it is a UIView and has certain expected behaviors and capabilities as a result. In Chameleon, it is still a UIView, but it is presented as an NSAlert and that is simply how it should be to achieve a more native feel but it also means any UIView tricks that may have worked with a UIAlertView on iOS will not work the same under Chameleon. UIActionSheet and UITextView are other examples of areas that have sometimes large but intentional differences.)

## Usage

Chameleon is actually a collection of several frameworks, the largest of which is UIKit. The others are mostly stubs that made porting simple demos and test apps from iOS very simple with minimal (in some cases, zero) code changes and may or may not be necessary for you.

The Xcode projects build embeddable frameworks which can then be bundled within your own app's bundle and distributed in a self-contained way.

## Design

The UIKit port in Chameleon starts at a very low level and attempts to go so far as to even route UIEvent objects along a similar path starting in the single UIApplication instance and getting routed from there to the correct UIWindows and UIViews.

The interface between AppKit's NSViews and NSWindows and Chameleon's UIWindow and UIViews occurs at the "screen" level. UIKitView is an NSView which you add to your NSView hierarchy in whatever way you want. The UIKitView hosts a UIScreen instance which is home to UIKit's interface elements.

Each UIWindow belongs to a UIScreen, and UIViews must exist on UIWindows. This should mostly work the same as you've come to expect on iOS. An important thing to note is that Mac applications often have more than one window. If you use more than one UIKitView in your app, be aware that this means your application now has more than one UIScreen and as a result some methods such as [UIScreen mainScreen] may suddenly do unexpected things. When porting Twitterrific from iOS, this was one source of unexpected bugs as a few things were making assumptions about there only being a single, main screen since that is normal on current iOS devices.

Once a UIKitView exists and there's a UIScreen available to work with, your code can proceed to build a UIWindow and UIViews on top of it and be largely unaware that it is actually running on OSX instead of iOS. For those cases where you need to customize some UI, `UIUserInterfaceIdiomDesktop` has been added so that your code can differentiate between running on a pad, phone, or desktop in a consistent way. To keep code cross platform, the following is a good way to structure things so that Apple's UIKit doesn't encounter the unknown `UIUserInterfaceIdiomDesktop` symbol when compiling for iOS:

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
	// iPhone
	} else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
	// iPad
	} else {
	// Mac
	}

(You can always use #ifdef or other compile-time approaches for platform differentiation, too - especially since a Mac app built with Chameleon doesn't need to adapt to multiple UI idioms at runtime the way a universal iOS app does. I just find it nice to have a similar pattern for all 3 idioms - but maybe that's just me.)

You can usually just create an instance of your iOS app's UIApplicationDelegate object and then pass it into UIKitView's helper method `-launchApplicationWithDelegate:afterDelay:` which will emulate the startup process of an iOS app (it will even attempt to show a Default.png if a delay is given). You might perform this step in your NSApplicationDelegate object's `-applicationDidFinishLaunching:` method. It is not necessary to use UIKitView's helper method to "launch" your app, but it can be a good way to get started.

Generally the interfaces to the classes are the same as Apple's documented interfaces. Some objects have additional methods that are useful for OS X and are defined in `(ClassName)AppKitIntegration.h` headers which are not included by the standard `UIKit.h` header. To easily include all AppKit extensions into your code, import `UIKit/AppKitIntegration.h` when compiling on OS X. There are also a couple of non-standard UI classes defined such as UIKey and UIViewAdapter that I designed out of necessity. (Keyboard handling in particular is a weak spot of Apple's current UIKit and so I developed my own rough API in place of anything "official" being documented by Apple.)

## Examples

Right now there's hardly any demos or examples or documentation. There's a simple app called BigApple in the Examples folder which might be enough to get started. It also shows how the UIKit Xcode project can be referenced from another Xcode project and setup as a dependency so that it is built automatically when the BigApple project is built.

## Authors

The Chameleon project was created by Sean Heber (Twitter: [@BigZaphod](http://twitter.com/BigZaphod/)) of The Iconfactory and he wrote nearly all of the initial version over several months. Craig Hockenberry (Twitter: [@chockenberry](http://twitter.com/chockenberry/)) was the first user/tester of Chameleon and found many holes and edge cases in the first implementation.

## License

Copyright (c) 2011, The Iconfactory. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 
3. Neither the name of The Iconfactory nor the names of its contributors may
   be used to endorse or promote products derived from this software without
   specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


