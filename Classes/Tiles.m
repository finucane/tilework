//
//  Kite.m
//  Penrose
//
//  Created by finucane on 12/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Tiles.h"
#include <math.h>
#include "geometry.h"
#include "insist.h"

#define NEAR (PHI/3.0)
#define ARC_WIDTH (4*PHI/15)

#define DART_BIG_RADIUS (PHI / (1.0 + PHI))
#define DART_SMALL_RADIUS ((1.0 / PHI) / (1.0 + (1.0 / PHI)))
#define KITE_BIG_RADIUS ((PHI * PHI) / (PHI + 1.0))
#define KITE_SMALL_RADIUS (PHI - KITE_BIG_RADIUS)

#define RHOMBUS_SMALL_RADIUS (PHI/5.0)
#define RHOMBUS_BIG_RADIUS (PHI - RHOMBUS_SMALL_RADIUS)

#define ANGLE_36 (M_PI / 5.0)
#define ANGLE_72 (ANGLE_36 * 2.0)
#define ANGLE_144 (ANGLE_72 * 2.0)
#define ANGLE_90 (M_PI/2.0)
#define ANGLE_108 (ANGLE_180 - ANGLE_72)
#define ANGLE_180 M_PI
#define ANGLE_360 (2 * M_PI)

@implementation Kite


- (void) draw:(CGContextRef) context scale:(CGFloat)scale shadow:(BOOL)shadow
{
  [super draw:context scale: scale shadow:shadow];
  
  if ([Tile enableOrnaments])
  {
    if (showArcs)
    {
      CGFloat n = flipped ? -1.0 : 1.0;
      
      CGContextBeginPath (context);
      CGContextSetRGBStrokeColor (context, 0, 0, 0, 1);
      CGContextSetLineWidth(context, ARC_WIDTH * scale);
      CGContextAddArc (context, scale * points[0].x, scale * points[0].y,  scale * KITE_BIG_RADIUS, rotation + 0.0, rotation + n*ANGLE_72, flipped ? 1 : 0);
      CGContextStrokePath(context);//closes path      
      
      CGContextBeginPath (context);
      CGContextSetRGBStrokeColor (context, 1, 1, 1, 1);
      CGContextSetLineWidth(context, ARC_WIDTH * scale);
      CGContextAddArc (context, scale * points[2].x, scale * points[2].y,  scale * KITE_SMALL_RADIUS, rotation - n*ANGLE_72,
                       rotation + n * (-ANGLE_72 - ANGLE_144), flipped ? 0 : 1);
      CGContextStrokePath(context); // closes path
    }
  }
}

- (BOOL) joinTo:(Tile*)tile
{
  insist (tile);
  
  if ([tile type] == [self type])
  {
    /*sharp end end*/
    if ([self joinTo:tile myA:0 hisA:0 myB:3 hisB:1 angle: ANGLE_360-ANGLE_72])
      return YES;
    if ([self joinTo:tile myA:0 hisA:0 myB:1 hisB:3 angle: -(ANGLE_360-ANGLE_72)])
      return YES;
    
    /*fat end*/
    if ([self joinTo:tile myA:2 hisA:2 myB:3 hisB:1 angle: +ANGLE_144])
      return YES;
    if ([self joinTo:tile myA:2 hisA:2 myB:1 hisB:3 angle: -ANGLE_144])
      return YES;
  }
  else
  {
    /*long sides*/
    if ([self joinTo:tile myA:1 hisA:0 myB:0 hisB:1 angle:-ANGLE_180])
      return YES;
    if ([self joinTo:tile myA:0 hisA:3 myB:3 hisB:0 angle:-ANGLE_180])
      return YES;
    
    
    if ([self joinTo:tile myA:3 hisA:2 myB:2 hisB:3 angle:+ANGLE_144])
      return YES;
    if ([self joinTo:tile myA:2 hisA:1 myB:1 hisB:2 angle:-ANGLE_144])
      return YES;
  }
  return NO;
}

- (CGPoint*)shape
{
  return [Tile kitePoints];
}

- (CGPoint*) rotatablePointNearPoint:(CGPoint)point
{
  if (distance (points [0], point) <= NEAR)
    return &points [0];
  if (distance (points [1], point) <= NEAR)
    return &points [1];
  if (distance (points [3], point) <= NEAR)
    return &points [3];
  return 0;
}

- (int)type
{
  return KITE;
}

@end

@implementation Dart


- (void) draw:(CGContextRef) context scale:(CGFloat)scale shadow:(BOOL)shadow
{
  [super draw:context scale: scale shadow:shadow];
  
  if ([Tile enableOrnaments])
  {
    if (showArcs)
    {
      CGFloat n = flipped ? -1.0 : 1.0;
      CGContextBeginPath (context);

      CGContextSetRGBStrokeColor (context, 1, 1, 1, 1);
      CGContextSetLineWidth(context, ARC_WIDTH * scale);
      CGContextAddArc (context, scale * points[2].x, scale * points[2].y,  scale * DART_SMALL_RADIUS, rotation - n * ANGLE_36, rotation  - n * 7 * ANGLE_36, flipped ? 0 :1);
      CGContextStrokePath(context); //closes path
      
      CGContextBeginPath (context);
      CGContextSetRGBStrokeColor (context, 0, 0, 0, 1);
      CGContextSetLineWidth(context, ARC_WIDTH * scale);
      CGContextAddArc (context, scale * points[0].x, scale * points[0].y,  scale * DART_BIG_RADIUS, rotation + 0.0, rotation + n * ANGLE_72, flipped ? 1 : 0);
      CGContextStrokePath(context);     
      
      /*draw outline again because the arcs cut into it*/
      //[self drawOutline:context scale:scale shadow:shadow];
    }
  }
}

- (BOOL) joinTo:(Tile*)tile
{
  insist (tile);

  if ([tile type] == [self type])
  {
    if ([self joinTo:tile myA:3 hisA:1 myB:0 hisB:0 angle:-ANGLE_72])
      return YES;
    if ([self joinTo:tile myA:0 hisA:0 myB:1 hisB:3 angle:ANGLE_72])
      return YES;
        
  }
  else
  { 
    /*long sides*/
    if ([self joinTo:tile myA:0 hisA:1 myB:1 hisB:0 angle:+ANGLE_180])
      return YES;
    if ([self joinTo:tile myA:3 hisA:0 myB:0 hisB:3 angle:+ANGLE_180])
      return YES;
    
    
    if ([self joinTo:tile myA:2 hisA:3 myB:3 hisB:2 angle:-ANGLE_144])
      return YES;
    if ([self joinTo:tile myA:1 hisA:2 myB:2 hisB:1 angle:+ANGLE_144])
      return YES;
    
  }
  return NO;
}

- (CGPoint*)shape
{
  return [Tile dartPoints];
}

- (CGPoint*) rotatablePointNearPoint:(CGPoint)point
{
  if (distance (points [0], point) <= NEAR)
    return &points [0];
  if (distance (points [1], point) <= NEAR)
    return &points [1];
  if (distance (points [3], point) <= NEAR)
    return &points [3];
  return 0;
}

- (int)type
{
  return DART;
}

@end

@implementation Thin

- (void) draw:(CGContextRef) context scale:(CGFloat)scale shadow:(BOOL)shadow
{
  [super draw:context scale:scale shadow:shadow];
  
  if ([Tile enableOrnaments])
  {
    if (showArcs)
    {
      CGFloat n = flipped ? -1.0 : 1.0;

      CGContextBeginPath (context);
      CGContextSetRGBStrokeColor (context, 1, 1, 1, 1);
      CGContextSetLineWidth(context, ARC_WIDTH * scale);
      CGContextAddArc (context, scale * points[3].x, scale * points[3].y,  scale * RHOMBUS_SMALL_RADIUS, rotation + n * ANGLE_36, rotation + n * (ANGLE_36 + ANGLE_144), flipped ? 1 : 0);
      CGContextStrokePath(context); //closes path
      
      CGContextBeginPath (context);
      CGContextSetRGBStrokeColor (context, 0, 0, 0, 1);
      CGContextSetLineWidth(context, ARC_WIDTH * scale);
      CGContextAddArc (context, scale * points[1].x, scale * points[1].y,  scale * RHOMBUS_SMALL_RADIUS, rotation + 0, rotation - n * ANGLE_144, flipped ? 0: 1);
      CGContextStrokePath(context); //closes path
      
      /*draw outline again because the arcs cut into it*/
      //[self drawOutline:context scale:scale shadow:shadow];
    }
  }
}

- (BOOL) joinTo:(Tile*)tile
{
  insist (tile);
  
  if ([tile type] == [self type])
  {
    /*dark-dark*/
    if ([self joinTo:tile myA:0 hisA:2 myB:1 hisB:1 angle:-ANGLE_144])
      return YES;
    if ([self joinTo:tile myA:1 hisA:1 myB:2 hisB:0 angle:+ANGLE_144])
      return YES;
    if ([self joinTo:tile myA:3 hisA:3 myB:0 hisB:2 angle:+ANGLE_144])
      return YES;
    if ([self joinTo:tile myA:3 hisA:3 myB:2 hisB:0 angle:-ANGLE_144])
      return YES;
  }
  else
  { 
    /*small-small*/
    if ([self joinTo:tile myA:1 hisA:0 myB:2 hisB:3 angle:0])
      return YES;
    if ([self joinTo:tile myA:1 hisA:0 myB:0 hisB:1 angle:+ANGLE_144])
      return YES;
    
    /*big white-big*/
    if ([self joinTo:tile myA:3 hisA:3 myB:0 hisB:2 angle:+ANGLE_108])
      return YES;
    if ([self joinTo:tile myA:3 hisA:1 myB:2 hisB:2 angle:+ANGLE_36])
      return YES;
  }
  return NO;
}


- (CGPoint*)shape
{
  return [Tile thinPoints];
}

- (CGPoint*) rotatablePointNearPoint:(CGPoint)point
{
  if (distance (points [0], point) <= NEAR)
    return &points [0];
  if (distance (points [2], point) <= NEAR)
    return &points [2];
  return 0;
}

- (int)type
{
  return THIN;
}

@end


@implementation Thick

- (void) draw:(CGContextRef) context scale:(CGFloat)scale shadow:(BOOL)shadow
{
  [super draw:context scale:scale shadow:shadow];
  
  if ([Tile enableOrnaments])
  {
    if (showArcs)
    {
      CGFloat n = flipped ? -1.0 : 1.0;

      CGContextBeginPath (context);
      CGContextSetRGBStrokeColor (context, 1, 1, 1, 1);
      CGContextSetLineWidth(context, ARC_WIDTH * scale);

      CGContextAddArc (context, scale * points[2].x, scale * points[2].y,  scale * RHOMBUS_BIG_RADIUS, rotation- n * ANGLE_180 , rotation + n * (-ANGLE_180 + ANGLE_72), flipped ? 1 : 0);
      CGContextStrokePath(context);//closes path
      
      CGContextBeginPath (context);
      CGContextSetRGBStrokeColor (context, 0, 0, 0, 1);
      CGContextSetLineWidth(context, ARC_WIDTH * scale);
      CGContextAddArc (context, scale * points[0].x, scale * points[0].y,  scale * RHOMBUS_SMALL_RADIUS, rotation + 0.0, rotation + n * ANGLE_72, flipped ? 1 : 0);
      CGContextStrokePath(context);//closes path
      
      /*draw outline again because the arcs cut into it*/
      //[self drawOutline:context scale:scale shadow:shadow];
    }    
  }
}



- (BOOL) joinTo:(Tile*)tile
{
  insist (tile);
  
  if ([tile type] == [self type])
  {
    /*dark-dark*/
    if ([self joinTo:tile myA:0 hisA:0 myB:1 hisB:3 angle:+ANGLE_72])
      return YES;
    if ([self joinTo:tile myA:0 hisA:0 myB:3 hisB:1 angle:-ANGLE_72])
      return YES;
    
    /*big-big*/
    if ([self joinTo:tile myA:1 hisA:3 myB:2 hisB:2 angle:-ANGLE_72])
      return YES;
    if ([self joinTo:tile myA:3 hisA:1 myB:2 hisB:2 angle:+ANGLE_72])
      return YES;
  }
  else
  { 
    /*small-small*/
    if ([self joinTo:tile myA:0 hisA:1 myB:3 hisB:2 angle:0])
      return YES;
    if ([self joinTo:tile myA:0 hisA:1 myB:1 hisB:0 angle:-ANGLE_144])
      return YES;
    
    /*big white-big*/
    if ([self joinTo:tile myA:3 hisA:3 myB:2 hisB:0 angle:-ANGLE_108])
      return YES;
    if ([self joinTo:tile myA:1 hisA:3 myB:2 hisB:2 angle:-ANGLE_36])
      return YES;
  }
  return NO;
}

- (CGPoint*)shape
{
  return [Tile thickPoints];
}

- (CGPoint*) rotatablePointNearPoint:(CGPoint)point
{
  if (distance (points [0], point) <= NEAR)
    return &points [0];
  if (distance (points [1], point) <= NEAR)
    return &points [1];
  if (distance (points [2], point) <= NEAR)
    return &points [2];
  if (distance (points [3], point) <= NEAR)
    return &points [3];
  return 0;
}

- (int)type
{
  return THICK;
}

@end