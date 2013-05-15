//
//  MainViewController.m
//  Slide Drawer
//
//  Created by Patrick Pierson on 4/18/13.
//
//

#import "MainViewController.h"
#import "UINavigationController+PPSlideDrawer.h"
#import "PPSlideDrawerDelegate.h"
#import "RightDrawerViewController.h"
#import "LeftDrawerViewController.h"
#import "TopDrawerViewController.h"
#import "BottomDrawerViewController.h"

@interface MainViewController (){
    
}

@property (nonatomic, weak) IBOutlet UIButton* button;

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    [self.navigationController enableDrawerFunctionalityForCurrentViewController];
    [self.navigationController setMovementDirectionMask:(DrawerMovementDirectionUp | DrawerMovementDirectionDown | DrawerMovementDirectionLeft | DrawerMovementDirectionRight)];
}

- (void)viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationController setSlideDrawerDelegate:self];
    if(_selectedOptionFromLeft) [_button setTitle:_selectedOptionFromLeft forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - PPSlideDrawerDelegate methods
- (UIViewController*)navigationController:(UINavigationController*)navigationController viewControllerForDrawerMovementDirection:(DrawerMovementDirection)drawerMovementDirection{
    switch (drawerMovementDirection) {
        case DrawerMovementDirectionRight:
            return [[LeftDrawerViewController alloc] init];
            break;
        case DrawerMovementDirectionLeft:
            return [[RightDrawerViewController alloc] init];
            break;
        case DrawerMovementDirectionUp:
            return [[BottomDrawerViewController alloc] init];
            break;
        case DrawerMovementDirectionDown:
            return [[TopDrawerViewController alloc] init];
            break;
        default:
            break;
    }
    
    return nil;
}


- (BOOL)doesUseAlternateSlideScreenCapture{
    return YES;
}

- (UIImage*)alternateSlideScreenCaptureWithOriginalScreenCapture:(UIImage*)originalScreenCapture{
    return originalScreenCapture;
}

@end
