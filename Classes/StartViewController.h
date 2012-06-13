//
//  StartViewController.h
//  Penrose
//
//  Created by finucane on 1/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StartViewController : UIViewController
{
  id appDelegate;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil appDelegate:(id)theAppDelegate;
- (IBAction) kitesAndDarts:(id)sender;
- (IBAction) rhombuses:(id)sender;
- (IBAction) presets:(id)sender;

@end
