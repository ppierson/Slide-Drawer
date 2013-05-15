//
//  PPSlideDrawerDelegate.h
//  Slide Drawer
//
//  Created by Patrick Pierson on 4/19/13.
//
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
//  PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import "UINavigationController+PPSlideDrawer.h"

@protocol PPSlideDrawerDelegate <NSObject>

@required
//Delegate method to assign what view controller should be displayed when the drawer is uncovered
- (UIViewController*)navigationController:(UINavigationController*)navigationController viewControllerForDrawerMovementDirection:(DrawerMovementDirection)drawerMovementDirection;

@optional
//Returns true if slide drawer should use an alternate screen capture during slide animation
- (BOOL)doesUseAlternateSlideScreenCapture;

//Called if doesUseAlternateSlideScreenCapture returns true, should return custom uiimage to display in drawer animation
- (UIImage*)alternateSlideScreenCaptureWithOriginalScreenCapture:(UIImage*)originalScreenCapture;

@end
