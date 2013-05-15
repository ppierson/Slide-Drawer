//
//  MainViewController.h
//  Slide Drawer
//
//  Created by Patrick Pierson on 4/18/13.
//
//

#import <UIKit/UIKit.h>
#import "PPSlideDrawerDelegate.h"

@interface MainViewController : UIViewController <PPSlideDrawerDelegate>{
    
}

@property (nonatomic, strong) NSString* selectedOptionFromLeft;

@end
