//
//  Window.m
//  Penrose
//
//  Created by David Finucane on 12/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Window.h"
#import "insist.h"

#define THUMB_OFFSET (44.0 * 1.5)

@implementation Window

- (void)setAppDelegate:(PenroseAppDelegate*)anAppDelegate
{
  appDelegate = [anAppDelegate retain];
  tileView = nil;
}
- (void) dealloc
{
  [appDelegate release];
  [tileView release];
  [super dealloc];
} 

- (UIButton*) tileButtonAtPoint:(CGPoint)point event:(UIEvent*)event
{
  /*return which tile button's at point, if any*/

  UIButton*first = [appDelegate firstTileButton];
  UIButton*second = [appDelegate secondTileButton];
  insist (first && second);
  
  if ([first pointInside:[self convertPoint:point toView:first] withEvent:event])
    return first;
  else if ([second pointInside:[self convertPoint:point toView:second] withEvent:event])
    return second;
  return nil;
}

- (UIView *) hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  insist (appDelegate);
  
  /*if the color panel is up or if we are already dragging a tile or
    if the point isn't over a tile button then don't capture this event*/
  
  if (tileView || [appDelegate colorViewVisible] || ![appDelegate started] || ![self tileButtonAtPoint:point event:event])
    return [super hitTest:point withEvent:event];
  
  /*now we'll get a touches began for this event*/
  return self;
}

- (void)move:(NSSet *)touches withEvent:(UIEvent *)event
{
  insist (touches && event);
  insist (tileView);

  if ([[event allTouches] count] > 1)
  {
    NSLog (@"more than 1");
  }
  /*a finger came down. deal with it.*/
  UITouch*touch = [[event allTouches] anyObject];
  insist (touch);

  CGPoint location = [touch locationInView:self];
  location.x += 0;
  location.y -= THUMB_OFFSET;
  
  [tileView setCenter:location];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  insist (appDelegate);
  
  /*something is fucked up, you can have a touchesBegan even before a previous
    touch life cycle is overwith. so just ignore a second touch while a first
   one is going on. god knows what happens when this phantom touches event
   ends/moves/cancels.*/
  if (tileView) 
    return;

  insist (!tileView);
    
  UITouch*touch = [touches anyObject];
  insist (touch);
  CGPoint location = [touch locationInView:self];  
  tileButton = [self tileButtonAtPoint:location event:event];
  if (!tileButton) return;
  
  /*this just puts us back in cursor mode*/
  [appDelegate tileAction:tileButton forEvent:event];

  tileView = [appDelegate tileViewForButton:tileButton];
  insist (tileView);
  
  [self addSubview:tileView];
  [self move:touches withEvent:event];
}
  
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
  if (!tileView) return;

  [self move:touches withEvent:event];
}  

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
  if (!tileView) return;

  [tileView removeFromSuperview];
  tileView = nil;
}


- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
  UIView*view = (UIView*)context;
  insist (view);
  [view removeFromSuperview];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  if (!tileView) return;

  UITouch*touch = [touches anyObject];
  insist (touch);
  CGPoint location = [touch locationInView:self];  
  CGPoint tileLocation;
  tileLocation.x = location.x + 0;
  tileLocation.y = location.y - THUMB_OFFSET;
  location.x += 0;
  location.y -= THUMB_OFFSET;
  
  if ([appDelegate canDrop:tileButton atScreenPoint:location])
  {
    /*we can drop a tile here. do it and get rid of the tile view
      we were using to simulate the drag*/

    [appDelegate playTockSound];
    [appDelegate drop:tileButton atScreenPoint:location];
    [tileView removeFromSuperview];
    tileView = nil;
  }
  else
  {
    /*we can't drop. fade the dragged tile out so the user
      has some feedback that he was trying to drop a tile on another*/
    
    [appDelegate playNegativeSound];
    [UIView beginAnimations:@"tileView" context:tileView];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
    [tileView setAlpha:0.0];
    [UIView commitAnimations];
    tileView = nil;
    
  }
}


@end
