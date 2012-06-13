//
//  StartViewController.m
//  Penrose
//
//  Created by finucane on 1/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "StartViewController.h"
#import "PenroseAppDelegate.h"
#import "insist.h"

@implementation StartViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil appDelegate:(id)theAppDelegate
{
  if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
  {
    appDelegate = [theAppDelegate retain];
  }
  return self;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc
{
  [appDelegate release];
  [super dealloc];
}

- (IBAction) kitesAndDarts:(id)sender
{
  insist (appDelegate);
  [((PenroseAppDelegate*)appDelegate) startWithDartsAndKites:YES];
}

- (IBAction) rhombuses:(id)sender
{
  insist (appDelegate);
  [((PenroseAppDelegate*)appDelegate) startWithDartsAndKites:NO];
}


- (IBAction) presets:(id)sender
{
  insist (appDelegate);
  [((PenroseAppDelegate*)appDelegate) startWithPreset];
}

@end
