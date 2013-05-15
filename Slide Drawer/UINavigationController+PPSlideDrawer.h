//
//  UINavigationController+PPSlideDrawer.h
//
//  Created by Patrick Pierson on 4/16/13.
//  Copyright (c) 2013 Patrick Pierson. All rights reserved.
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

#import <UIKit/UIKit.h>

@protocol PPSlideDrawerDelegate;

typedef enum {
    DrawerMovementDirectionNone = 0,
    DrawerMovementDirectionDown = 1 << 0,
    DrawerMovementDirectionUp = 1 << 1,
    DrawerMovementDirectionLeft = 1 << 2,
    DrawerMovementDirectionRight = 1 << 3
} DrawerMovementDirection;

@interface UINavigationController (PPSlideDrawer)

//Enabled drawer functionality for top view controller of UINavigationController
- (void)enableDrawerFunctionalityForCurrentViewController;
//Sets Slide Drawer delegate
- (void)setSlideDrawerDelegate:(id<PPSlideDrawerDelegate>)delegate;
//Gets Slide Drawer delegate
- (id<PPSlideDrawerDelegate>)getSlideDrawerDelegate;

//Sets mask of allowed movement directions of drawer
- (void)setMovementDirectionMask:(int)movementDirectionMask;
//Gets mask of allowed movement directions of drawer
- (int)getMovementDirectionMask;
//auto shuts the drawer if open
- (void)autoShutDrawer;
@end
