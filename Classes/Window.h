//
//  Window.h
//  Penrose
//
//  Created by David Finucane on 12/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PenroseAppDelegate.h"

@interface Window : UIWindow
{
  PenroseAppDelegate*appDelegate;
  UIButton*tileButton;
  UIView*tileView;
}

- (void)setAppDelegate:(PenroseAppDelegate*)anAppDelegate;
@end
