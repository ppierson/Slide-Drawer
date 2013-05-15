//
//  UINavigationController+PPSlideDrawer.m
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

#import "UINavigationController+PPSlideDrawer.h"
#import "PPSlideDrawerDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

/** Modify this number to change how much of the screen overlay is still visible when drawer layout is anchored */
#define DRAWER_IMAGE_ANCHOR_WIDTH 60
/** The view tag used (in drawer view controller's view) to identify view controllers as drawers */
#define DRAWER_IMAGE_TAG 99999
/** The shadow radius of drawer image */
#define DRAWER_IMAGE_SHADOW_RADIUS 5.0
/** The shadow opacity of drawer image */
#define DRAWER_IMAGE_SHADOW_OPACITY 0.5

#define TOP_VIEW_PAN_THRESHOLD 30.0
#define DRAWER_IMAGE_VELOCITY_THRESHOLD 100.0
#define DRAWER_FULL_ANIMATION_TIME 0.2

static char const * const drawerDelegateKey = "drawerDelegateKey";
static char const * const movementDirectionMaskKey = "movementDirectionMaskKey";
static char const * const currentMovementDirectionKey = "currentMovementDirectionKey";
static char const * const drawerIsOpenKey = "drawerIsOpenKey";
static char const * const upPanViewControllerKey = "upPanViewControllerKey";
static char const * const downPanViewControllerKey = "downPanViewControllerKey";
static char const * const leftPanViewControllerKey = "leftPanViewControllerKey";
static char const * const rightPanViewControllerKey = "rightPanViewControllerKey";

@implementation UINavigationController (PPSlideDrawer)

+ (UIImage*)screenshot
{
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    // Create a graphics context with the target size
    // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
    // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    if (NULL != UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    else
        UIGraphicsBeginImageContext(imageSize);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Iterate over every window from back to front
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
    {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
        {
            // -renderInContext: renders in the coordinate space of the layer,
            // so we must first apply the layer's geometry to the graphics context
            CGContextSaveGState(context);
            // Center the context around the window's anchor point
            CGContextTranslateCTM(context, [window center].x, [window center].y - statusBarFrame.size.height);
            // Apply the window's transform about the anchor point
            CGContextConcatCTM(context, [window transform]);
            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y);
            
            // Render the layer hierarchy to the current context
            [[window layer] renderInContext:context];
            
            // Restore the context
            CGContextRestoreGState(context);
        }
    }
    
    // Retrieve the screenshot image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage*)getScreenCapture{
    UIImage* defaultScreenCapture = [[self class] screenshot];
    id<PPSlideDrawerDelegate> delegate = [self getSlideDrawerDelegate];
    if(delegate && (id)delegate != [NSNull null]){
        if([delegate respondsToSelector:@selector(doesUseAlternateSlideScreenCapture)] && [delegate doesUseAlternateSlideScreenCapture]){
            NSAssert([delegate respondsToSelector:@selector(alternateSlideScreenCaptureWithOriginalScreenCapture:)], @"<UINavigationController+PPSlideDrawer> Error: PPSlideDrawer delegate does not respond to selector alternateSlideScreenCaptureWithOriginalScreenCapture:. Delegate must implement this method when using an alternate screen capture.");
            return [delegate alternateSlideScreenCaptureWithOriginalScreenCapture:defaultScreenCapture];
        }
    }
    
    return defaultScreenCapture;
}

+ (CGRect)statusBarFrameWithView:(UIView*)view {
    return [view convertRect:[view.window convertRect:[[UIApplication sharedApplication] statusBarFrame] fromWindow:nil] fromView:nil];
}

+ (CGRect)statusBarFrame{
    return [[UIApplication sharedApplication] statusBarFrame];
}

- (void)enableDrawerFunctionalityForViewController:(UIViewController*)viewController{
    UIView* view = viewController.view;
    UIPanGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(topViewPanGesture:)];
    [panGestureRecognizer setMinimumNumberOfTouches:1];
    [panGestureRecognizer setMaximumNumberOfTouches:1];
    [view addGestureRecognizer:panGestureRecognizer];
}

- (void)enableDrawerFunctionalityForCurrentViewController{
    [self enableDrawerFunctionalityForViewController:self.topViewController];
}

#pragma mark - Associated Objects(faked iVars)
- (void)setSlideDrawerDelegate:(id<PPSlideDrawerDelegate>)delegate{
    objc_setAssociatedObject(self, drawerDelegateKey, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<PPSlideDrawerDelegate>)getSlideDrawerDelegate{
    id obj = objc_getAssociatedObject(self, drawerDelegateKey);
    return obj;
}

- (void)setMovementDirectionMask:(int)movementDirectionMask {
    NSNumber* mask = [NSNumber numberWithInt:movementDirectionMask];
    objc_setAssociatedObject(self, movementDirectionMaskKey, mask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (int)getMovementDirectionMask{
    id obj = objc_getAssociatedObject(self, movementDirectionMaskKey);
    NSNumber* mask = (NSNumber*)obj;
    return [mask intValue];
}

- (void)setCurrentMovementDirection:(DrawerMovementDirection)drawerMovementDirection{
    NSNumber* direction = [NSNumber numberWithInt:drawerMovementDirection];
    objc_setAssociatedObject(self, currentMovementDirectionKey, direction, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (DrawerMovementDirection)getCurrentMovementDirection{
    id obj = objc_getAssociatedObject(self, currentMovementDirectionKey);
    NSNumber* directionNumber = (NSNumber*)obj;
    DrawerMovementDirection direction = [directionNumber intValue];
    return direction;
}

- (void)setDrawerIsOpen:(BOOL)isOpen{
    NSNumber* isOpenNumber = [NSNumber numberWithBool:isOpen];
    objc_setAssociatedObject(self, drawerIsOpenKey, isOpenNumber, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isDrawerOpen{
    id obj = objc_getAssociatedObject(self, drawerIsOpenKey);
    NSNumber* open = (NSNumber*)obj;
    return [open boolValue];
}

#pragma mark - Drawer Push and Pop
- (void)pushAndDragDrawerViewController:(UIViewController*)viewController andGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer{
    UIImage* image = [self getScreenCapture];
    CGRect frame = self.view.window.bounds;
    frame.origin.y += [[self class] statusBarFrame].size.height;
    
    // Make the drawer visible but overlayed with the screen capture
    UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = frame;
    imageView.tag = DRAWER_IMAGE_TAG;
    imageView.layer.shadowOffset = CGSizeZero;
    imageView.layer.shadowRadius = DRAWER_IMAGE_SHADOW_RADIUS;
    imageView.layer.shadowColor = [UIColor blackColor].CGColor;
    imageView.layer.shadowOpacity = DRAWER_IMAGE_SHADOW_OPACITY;
    imageView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.view.window.layer.bounds].CGPath;
    [[[UIApplication sharedApplication] keyWindow] addSubview:imageView];

    [viewController.view addGestureRecognizer:gestureRecognizer];
    
    viewController.hidesBottomBarWhenPushed = YES;
    [self setNavigationBarHidden:YES animated:NO];
    [self pushViewController:viewController animated:NO];
}

- (void)popDrawerViewController{
    UIImageView* img = (UIImageView*) [[[UIApplication sharedApplication] keyWindow] viewWithTag:DRAWER_IMAGE_TAG];
    [img removeFromSuperview];
    UIViewController* previousController = [self.viewControllers objectAtIndex:[self.viewControllers count]-2];
    [self popViewControllerAnimated:NO];
    [self setCurrentMovementDirection:DrawerMovementDirectionNone];
    [self performSelector:@selector(enableDrawerFunctionalityForViewController:) withObject:previousController afterDelay:0.01f];
}

- (void)autoShutDrawer{
    UIImageView* img = (UIImageView*) [[[UIApplication sharedApplication] keyWindow] viewWithTag:DRAWER_IMAGE_TAG];
    BOOL screenImageFound = (img && (id) img != [NSNull null]);
    if(screenImageFound){
        CGRect frameOfImage = img.frame;
        frameOfImage.origin = CGPointMake(0, [[self class] statusBarFrame].size.height);
        [UIView animateWithDuration:DRAWER_FULL_ANIMATION_TIME
                         animations:^{
                             img.frame = frameOfImage;
                         }
                         completion:^(BOOL finished){
                             [self setDrawerIsOpen:NO];
                             [self popDrawerViewController];
                         }];
    }
}

#pragma mark - Movement
- (void)moveScreenOverlayImageView:(UIImageView*)imageView overView:(UIView*)topView withPanGestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer{
    DrawerMovementDirection movementDirection = [self getCurrentMovementDirection];
    BOOL isDrawerOpen = [self isDrawerOpen];
    CGRect frameOfImage = imageView.frame;
    
    CGPoint translationInTop = [gestureRecognizer translationInView:topView];
    CGPoint velocity = [gestureRecognizer velocityInView:topView];
    if(gestureRecognizer.state == UIGestureRecognizerStateChanged){
        //Drawer is open, start animating(follow finger)
        
        switch (movementDirection) {
            case DrawerMovementDirectionUp:
                frameOfImage.origin.y = (!isDrawerOpen) ? translationInTop.y : (DRAWER_IMAGE_ANCHOR_WIDTH - topView.frame.size.height + translationInTop.y);
                //Lock to bounds
                if(frameOfImage.origin.y < DRAWER_IMAGE_ANCHOR_WIDTH - topView.frame.size.height) frameOfImage.origin.y = DRAWER_IMAGE_ANCHOR_WIDTH - topView.frame.size.height;
                else if(frameOfImage.origin.y > [[self class] statusBarFrame].size.height) frameOfImage.origin.y = [[self class] statusBarFrame].size.height;
                break;
            case DrawerMovementDirectionDown:
                frameOfImage.origin.y = (!isDrawerOpen) ? translationInTop.y : (topView.frame.size.height - DRAWER_IMAGE_ANCHOR_WIDTH + translationInTop.y);
                //Lock to bounds
                if(frameOfImage.origin.y > topView.frame.size.height - DRAWER_IMAGE_ANCHOR_WIDTH) frameOfImage.origin.y = topView.frame.size.height - DRAWER_IMAGE_ANCHOR_WIDTH;
                else if(frameOfImage.origin.y < [[self class] statusBarFrame].size.height) frameOfImage.origin.y = [[self class] statusBarFrame].size.height;
                break;
            case DrawerMovementDirectionLeft:
                frameOfImage.origin.x = (!isDrawerOpen) ? translationInTop.x : (DRAWER_IMAGE_ANCHOR_WIDTH - topView.frame.size.width + translationInTop.x);
                //Lock to bounds
                if(frameOfImage.origin.x < DRAWER_IMAGE_ANCHOR_WIDTH - topView.frame.size.width) frameOfImage.origin.x = DRAWER_IMAGE_ANCHOR_WIDTH - topView.frame.size.width;
                else if(frameOfImage.origin.x > 0) frameOfImage.origin.x = 0;
                break;
            case DrawerMovementDirectionRight:
                frameOfImage.origin.x = (!isDrawerOpen) ? translationInTop.x : (topView.frame.size.width - DRAWER_IMAGE_ANCHOR_WIDTH + translationInTop.x);
                //Lock to bounds
                if(frameOfImage.origin.x > topView.frame.size.width - DRAWER_IMAGE_ANCHOR_WIDTH) frameOfImage.origin.x = topView.frame.size.width - DRAWER_IMAGE_ANCHOR_WIDTH;
                else if(frameOfImage.origin.x < 0) frameOfImage.origin.x = 0;
                break;
                
            default:
                break;
        }
        imageView.frame = frameOfImage;
    }else if(gestureRecognizer.state == UIGestureRecognizerStateEnded){
        //finger released, set to appropriate state
        CGPoint animateTo = CGPointMake(0, [[self class] statusBarFrame].size.height);
        if(movementDirection == DrawerMovementDirectionUp){
            if(velocity.y < -DRAWER_IMAGE_VELOCITY_THRESHOLD){
                animateTo.y = DRAWER_IMAGE_ANCHOR_WIDTH - topView.frame.size.height;
            }else if(velocity.y > DRAWER_IMAGE_VELOCITY_THRESHOLD){
                //nothing
            }else if(frameOfImage.origin.y < -(topView.frame.size.height / 2.0f)){
                animateTo.y = DRAWER_IMAGE_ANCHOR_WIDTH - topView.frame.size.height;
            }
        }else if(movementDirection == DrawerMovementDirectionDown){
            if(velocity.y > DRAWER_IMAGE_VELOCITY_THRESHOLD){
                animateTo.y = topView.frame.size.height - DRAWER_IMAGE_ANCHOR_WIDTH;
            }else if(velocity.y < -DRAWER_IMAGE_VELOCITY_THRESHOLD){
                //nothing
            }else if(frameOfImage.origin.y > topView.frame.size.height / 2.0f){
                animateTo.y = topView.frame.size.height - DRAWER_IMAGE_ANCHOR_WIDTH;
            }
        }else if(movementDirection == DrawerMovementDirectionLeft){
            if(velocity.x < -DRAWER_IMAGE_VELOCITY_THRESHOLD){
                animateTo.x = DRAWER_IMAGE_ANCHOR_WIDTH - topView.frame.size.width;
            }else if(velocity.x > DRAWER_IMAGE_VELOCITY_THRESHOLD){
                //nothing
            }else if(frameOfImage.origin.x < -(topView.frame.size.width / 2.0f)){
                animateTo.x = DRAWER_IMAGE_ANCHOR_WIDTH - topView.frame.size.width;
            }
        }else if(movementDirection == DrawerMovementDirectionRight){
            if(velocity.x > DRAWER_IMAGE_VELOCITY_THRESHOLD){
                animateTo.x = topView.frame.size.width - DRAWER_IMAGE_ANCHOR_WIDTH;
            }else if(velocity.x < -DRAWER_IMAGE_VELOCITY_THRESHOLD){
                //nothing
            }else if(frameOfImage.origin.x > topView.frame.size.width / 2.0f){
                animateTo.x = topView.frame.size.width - DRAWER_IMAGE_ANCHOR_WIDTH;
            }
        }
        
        frameOfImage.origin = animateTo;
        [gestureRecognizer setEnabled:NO];
        [UIView animateWithDuration:DRAWER_FULL_ANIMATION_TIME
                         animations:^{
                             imageView.frame = frameOfImage;
                         }
                         completion:^(BOOL finished){
                             if(animateTo.x == 0 && animateTo.y == [[self class] statusBarFrame].size.height){
                                 [self setDrawerIsOpen:NO];
                                 [self popDrawerViewController];
                             }else{
                                 [topView removeGestureRecognizer:gestureRecognizer];
                                 [imageView setUserInteractionEnabled:YES];
                                 [self setDrawerIsOpen:YES];
                                 UIPanGestureRecognizer* panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(screenImagePanGesture:)];
                                 [panRecognizer setMaximumNumberOfTouches:1];
                                 [panRecognizer setMinimumNumberOfTouches:1];
                                 [imageView addGestureRecognizer:panRecognizer];
                                 UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenImageTapGesture:)];
                                 [tapRecognizer setNumberOfTapsRequired:1];
                                 [tapRecognizer setNumberOfTouchesRequired:1];
                                 [imageView addGestureRecognizer:tapRecognizer];
                             }
                         }];
    }
}

#pragma mark - Gesture Control For Top View
- (void)topViewPanGesture:(UIPanGestureRecognizer *)gestureRecognizer{
    int movementMask = [self getMovementDirectionMask];
    UIView* topview = self.topViewController.view;
    CGPoint translationInTop = [gestureRecognizer translationInView:topview];
    
    UIImageView* img = (UIImageView*) [[[UIApplication sharedApplication] keyWindow] viewWithTag:DRAWER_IMAGE_TAG];
    BOOL screenImageFound = (img && (id) img != [NSNull null]);
    
    if(!screenImageFound){
        //Drawer is not open, open it
        int absX = ABS(translationInTop.x);
        int absY = ABS(translationInTop.y);
        DrawerMovementDirection directionToMove = DrawerMovementDirectionNone;
        if ((absX > absY) && absX > TOP_VIEW_PAN_THRESHOLD) {
            if(translationInTop.x < 0 && (movementMask & DrawerMovementDirectionLeft) == DrawerMovementDirectionLeft){
                directionToMove = DrawerMovementDirectionLeft;
            }else if(translationInTop.x > 0 && (movementMask & DrawerMovementDirectionRight) == DrawerMovementDirectionRight){
                directionToMove = DrawerMovementDirectionRight;
            }
        }else if((absX < absY) && absY > TOP_VIEW_PAN_THRESHOLD){
            if(translationInTop.y < 0 && (movementMask & DrawerMovementDirectionUp) == DrawerMovementDirectionUp){
                directionToMove = DrawerMovementDirectionUp;
            }else if(translationInTop.y > 0 && (movementMask & DrawerMovementDirectionDown) == DrawerMovementDirectionDown){
                directionToMove = DrawerMovementDirectionDown;
            }
        }
        
        if(directionToMove != DrawerMovementDirectionNone){
            id<PPSlideDrawerDelegate> delegate = [self getSlideDrawerDelegate];
            if(delegate && (id)delegate != [NSNull null]){
                NSAssert([delegate respondsToSelector:@selector(navigationController:viewControllerForDrawerMovementDirection:)], @"<UINavigationController+PPSlideDrawer> Error: PPSlideDrawer delegate does not respond to selector navigationController:viewControllerForDrawerMovementDirection:");
                
                UIViewController* viewController = [delegate navigationController:self viewControllerForDrawerMovementDirection:directionToMove];
                if(viewController && (id)viewController != [NSNull null]){
                    [self pushAndDragDrawerViewController:viewController andGestureRecognizer:gestureRecognizer];
                    [self setCurrentMovementDirection:directionToMove];
                }else{
                    NSLog(@"<UINavigationController+PPSlideDrawer> Error: Attempting to push nil UIViewController to drawer!");
                }
            }else{
                NSLog(@"<UINavigationController+PPSlideDrawer> Error: Slide Drawer delegate must be set!");
            }
        }
        
    }else{
        [self moveScreenOverlayImageView:img overView:topview withPanGestureRecognizer:gestureRecognizer];
    }
}

#pragma mark - Gesture Control For Open Drawer
- (void)screenImagePanGesture:(UIPanGestureRecognizer *)gestureRecognizer{
    UIView* topview = self.topViewController.view;
    UIImageView* img = (UIImageView*) gestureRecognizer.view;
    [self moveScreenOverlayImageView:img overView:topview withPanGestureRecognizer:gestureRecognizer];
}

- (void)screenImageTapGesture:(UITapGestureRecognizer *)gestureRecognizer{
    [self autoShutDrawer];
}

@end
