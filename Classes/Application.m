//
//  Application.m
//  Tilework
//
//  Created by finucane on 1/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Application.h"

extern void report_assertion (NSString*msg);

@implementation Application
- (BOOL)sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event
{
  @try
  {
    return [super sendAction:action to:target from:sender forEvent:event];
  }
  @catch (NSException*e)
  {
    report_assertion ([NSString stringWithFormat:@"%@%@", [e name], [e reason]]);
    return YES;
  }
  return YES;
}
- (void)sendEvent:(UIEvent *)event
{
  @try
  {
    [super sendEvent:event];
  }
  @catch (NSException*e)
  {
    report_assertion ([NSString stringWithFormat:@"%@%@", [e name], [e reason]]);
  }
}

@end
