//
//  main.m
//  Penrose
//
//  Created by David Finucane on 12/16/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[])
{    
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  int retVal;
  
  /*there is no way to report exceptions correctly on iphone os so just do
   something quick and dirty with NSLog.*/
  
  @try
  {
    retVal = UIApplicationMain(argc, argv, @"Application", nil);
  }
  @catch (NSException*exception)
  {
    NSLog ([NSString stringWithFormat:@"%@%@", [exception name], [exception reason]]);
  }
  [pool release];
  return retVal;
}