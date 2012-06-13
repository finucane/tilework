//
//  Tile.m
//  Penrose
//
//  Created by David Finucane on 12/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Tile.h"
#import "insist.h"
#import "geometry.h"
#import "Tiles.h"

@implementation Tile

#define NUM_POINTS 4
#define JOIN_PROXIMITY (PHI/2.0)
#define ABUT_PROXIMITY (PHI/5.0)
#define SMALL_PIECE_OF_SEGMENT (PHI/3.0)

#define HIT_PIXELS 44
#define ROTATE_PIXELS (HIT_PIXELS * 1.2)
#define FRAME_PIXELS (HIT_PIXELS * 3.8)
#define FRAME_ALPHA 0.3
static CGFloat theScale = 1.0;
static CGPoint theKitePoints [NUM_POINTS];
static CGPoint theDartPoints [NUM_POINTS];
static CGPoint theThinPoints [NUM_POINTS];
static CGPoint theThickPoints [NUM_POINTS];
static BOOL enableOrnaments = YES;

#define NUM_FRAME_POINTS 4

+ (void) initialize
{
  CGFloat x, y;
  
  /*set up the basic shape of the kite, centered at (0,0)*/
  theKitePoints[0].x = 0.0;
  theKitePoints[0].y = 0.0;
  theKitePoints[1].x = PHI * cos (2.0 * M_PI / 5.0);
  theKitePoints[1].y = PHI * sin (2.0 * M_PI / 5.0);
  theKitePoints[2].x = PHI * cos (M_PI / 5.0);
  theKitePoints[2].y = PHI * sin (M_PI / 5.0);
  theKitePoints[3].x = PHI;
  theKitePoints[3].y = 0;
  centroid (theKitePoints, NUM_POINTS, &x, &y);
  move (theKitePoints, NUM_POINTS, -x, -y);
  
  /*now the dart*/
  theDartPoints[0].x = 0.0;
  theDartPoints[0].y = 0.0;
  theDartPoints[1].x = PHI * cos (2.0 * M_PI / 5.0);
  theDartPoints[1].y = PHI * sin (2.0 * M_PI / 5.0);
  theDartPoints[2].x = cos (M_PI / 5.0);
  theDartPoints[2].y = sin (M_PI / 5.0);
  theDartPoints[3].x = PHI;
  theDartPoints[3].y = 0;
  centroid (theDartPoints, NUM_POINTS, &x, &y);
  move (theDartPoints, NUM_POINTS, -x, -y);
  
  /*now the thin rhombus*/
  theThinPoints[0].x = 0.0;
  theThinPoints[0].y = 0.0;
  theThinPoints[1].x = PHI * cos (M_PI / 5.0);
  theThinPoints[1].y = PHI * sin (M_PI / 5.0);
  theThinPoints[2].x = PHI * cos (M_PI / 5.0) + PHI;
  theThinPoints[2].y = PHI * sin (M_PI / 5.0);
  theThinPoints[3].x = PHI;
  theThinPoints[3].y = 0;
  centroid (theThinPoints, NUM_POINTS, &x, &y);
  move (theThinPoints, NUM_POINTS, -x, -y);
  
  /*now the thick rhombus. it's just like the thin but w/ a (0,0) angle twice as big*/
  theThickPoints[0].x = 0.0;
  theThickPoints[0].y = 0.0;
  theThickPoints[1].x = PHI * cos (2.0 * M_PI / 5.0);
  theThickPoints[1].y = PHI * sin (2.0 * M_PI / 5.0);
  theThickPoints[2].x = PHI * cos (2.0 * M_PI / 5.0) + PHI;
  theThickPoints[2].y = PHI * sin (2.0 * M_PI / 5.0);
  theThickPoints[3].x = PHI;
  theThickPoints[3].y = 0;
  centroid (theThickPoints, NUM_POINTS, &x, &y);
  move (theThickPoints, NUM_POINTS, -x, -y);
}

+ (BOOL) enableOrnaments
{
  return enableOrnaments;
}

+ (void) setEnableOrnaments:(BOOL)b
{
  enableOrnaments = b;
}

+ (void) setScale:(CGFloat)scale
{
  insist (scale);
  theScale = scale;
}

+ (CGFloat) scale
{
  return theScale;
}

+ (CGPoint*) dartPoints
{
  return theDartPoints;
}

+ (CGPoint*) kitePoints
{
  return theKitePoints;
}

+ (CGPoint*) thinPoints
{
  return theThinPoints;
}

+ (CGPoint*) thickPoints
{
  return theThickPoints;
}

+ (unsigned) numberFromColor:(UIColor*)color
{
  CGColorRef ref = [color CGColor];
  insist (ref);
  insist (CGColorGetNumberOfComponents (ref) == 4);
  const CGFloat*components = CGColorGetComponents (ref);
  
  return
  (((unsigned)(components [2] * 255.0))) +
  (((unsigned)(components [1] * 255.0)) << 8) +
  (((unsigned)(components [0] * 255.0)) << 16);
}

+ (UIColor*)colorFromUnsigned:(unsigned)n
{
  CGFloat r,g,b;
  b = ((CGFloat)(n & 0xff)) / 255.0;
  g = ((CGFloat)((n >> 8) & 0xff)) / 255.0;
  r = ((CGFloat)((n >> 16) & 0xff)) / 255.0;
  return [UIColor colorWithRed:r green:g blue:b alpha:1.0];
}

+ (Tile*)tileOfType:(int)type color:(UIColor*)color
{
  Tile*tile;
  if (type == KITE) tile = [[[Kite alloc] initWithColor:color] autorelease];
  else if (type == DART) tile = [[[Dart alloc] initWithColor:color] autorelease];
  else if (type == THIN) tile = [[[Thin alloc] initWithColor:color] autorelease];
  else if (type == THICK) tile = [[[Thick alloc] initWithColor:color] autorelease];
 
  return tile;
}

+ (CGFloat) frameEdge
{
  /*get default size of frame in tile units*/
  CGFloat edge = FRAME_PIXELS / [Tile scale];
  CGFloat tileEdge = 2.0 * PHI;
  
  /*make an edge FRAME_PIXELS long except if it needs to be bigger to go around a tile*/
  return edge > tileEdge ? edge : tileEdge;
}

- (id) initWithColor:(UIColor*)aColor
{
  insist (aColor);
  self = [super init];
  rotation = 0.0;
  [self moveToX:0.0 toY:0.0];
  for (int i = 0; i < NUM_POINTS; i++)
    neighbors [i] = nil;
  color = [aColor retain];
  showArcs = NO;
  flipped = NO;
  return self;
}

- (void) dealloc
{
  [color release];
  [super dealloc];
}

/*yes if the tile is completely surrounded by neighbors*/
- (BOOL) landLocked
{
  for (int i = 0; i < NUM_POINTS; i++)
    if (!neighbors [i])
      return NO;
  return YES;
}

/*yes if the tile is all alone*/
- (BOOL) islanded
{
  for (int i = 0; i < NUM_POINTS; i++)
    if (neighbors [i])
      return NO;
  return YES;
}

- (void) updateFrame
{  
  insist (framed);
  CGFloat frameEdge = [Tile frameEdge];
  
  /*make a square around the origin*/
  frame[0].x = - frameEdge/2.0;
  frame[0].y = - frameEdge/2.0;
  frame[1].x = + frameEdge/2.0;
  frame[1].y = - frameEdge/2.0;
  frame[2].x = + frameEdge/2.0;
  frame[2].y = + frameEdge/2.0;
  frame[3].x = - frameEdge/2.0;
  frame[3].y = + frameEdge/2.0;
  
  /*now rotate it*/
  rotate (frame, NUM_FRAME_POINTS, rotation);
  
  /*now translate it*/
  move (frame, NUM_FRAME_POINTS, origin.x, origin.y);
}


/*move the tile*/
- (void) moveToX:(CGFloat)x toY:(CGFloat)y
{
  /*move*/
  origin.x = x;
  origin.y = y;
  
  /*rotate*/
  [self rotateBy:0];
  
  if (framed) [self updateFrame];
}

- (void) moveByX:(CGFloat)x byY:(CGFloat)y
{
  [self moveToX: origin.x + x toY:origin.y + y];
}

/*rotate the tile. the basic shape is centered at the origin so this is easy*/
- (void) rotateBy:(CGFloat)radians
{
  /*remember the new rotation*/
  rotation += radians;
  rotation = normalize_angle (rotation);
  
  /*do our trigonometry*/
  CGFloat s = sin (rotation);
  CGFloat c = cos (rotation);
  
  /*get basic shape*/
  CGPoint*shape = [self shape];
  
  /*recompute actual polygon*/
  for (int i = 0; i < NUM_POINTS; i++)
  {
    points [i].x = c * shape [i].x - s * shape [i].y + origin.x;
    points [i].y = s * shape [i].x + c * shape [i].y + origin.y;
  }
  if (framed) [self updateFrame];
}

/*return yes if any part of the tile is inside the rectangle*/
- (BOOL) isAtLeastPartiallyInsideRect:(CGRect)rect
{
  for (int i = 0; i < NUM_POINTS; i++)
  {
    if (CGRectContainsPoint (rect, points [i]))
      return YES;
  }
  return NO;
}

- (CGFloat) getRotationFromPoint:(CGPoint)from toPoint:(CGPoint)to
{
  if (from.x == to.x && from.y == to.y) return 0;
  
  /*because i am incapable of math move everything to the origin*/
  from.x -= origin.x;
  from.y -= origin.y;
  to.x -= origin.x;
  to.y -= origin.y;
  
  /*vector math*/
  CGPoint v;
  v.x = to.x - from.x;
  v.y = to.y - from.y;
  
  CGFloat mFrom = magnitude (from);
  CGFloat mTo = magnitude (to);
  CGFloat mV = magnitude (v);  
  
  /*avoid chaos*/
  if (mFrom == 0.0 || mTo == 0.0) return 0;
  CGFloat arg = ((mFrom*mFrom + mTo*mTo - mV*mV)/(2.0 * mFrom*mTo));
  if (arg <= -1.0 || arg >= 1.0)
    return 0;
  
  CGFloat w = acos (arg);
  
  /*compute where from would go if it were rotated by w*/
  CGFloat s = sin (w);
  CGFloat c = cos (w);
  CGFloat x = from.x;
  CGFloat y = from.y;
  CGPoint p;
  p.x = c * x - s * y;
  p.y = s * x + c * y;
  
  /*if it is further away from "to" than "from" then a positive angle
   goes the wrong way*/
  if (distance (to, p) > distance (from, to))
    return -w;
  return w;
}

- (BOOL) cannotIntersectPoint:(CGPoint)point
{
  return distance (origin, point) > PHI * 2;
}

- (BOOL) cannotIntersectTile:(Tile*)tile
{
  return distance (origin, tile->origin) > PHI * 2;
}

- (BOOL) cannotAbutTile:(Tile*)tile
{
  return [self cannotIntersectPoint:tile->origin];
}

- (CGPoint*) framedRotatablePointNearPoint:(CGPoint)point
{
  insist (framed);
  
  /*if we get a hit return it in our persistant framePoint*/
  CGFloat near = ROTATE_PIXELS / [Tile scale];
  
  if (distance (frame [0], point) <= near)
    return &frame [0];
  else if (distance (frame [1], point) <= near)
    return &frame [1];
  else if (distance (frame [2], point) <= near)
    return &frame [2];
  else if (distance (frame [3], point) <= near)
    return &frame [3];
  else return 0;
}


- (BOOL) framedContainsPoint:(CGPoint)point
{
  insist (framed);
  
  CGFloat edge = distance (frame[0], frame [1]);
  
  /*do a coarse test*/
  if (distance (origin, point) > 2 * edge)
   return NO;

  /*it might intersect. do the hard work to find out*/
  return point_inside_polygon (frame, NUM_FRAME_POINTS, CGPointMake (0, 0), point);
}

- (BOOL) containsPoint:(CGPoint)point
{
  /*first do the easy test*/
  if ([self cannotIntersectPoint: point])
    return NO;

  /*ok it might intersect. do the hard work to find out*/
  return point_inside_polygon (points, NUM_POINTS, CGPointMake (0, 0), point);
}

- (BOOL) intersectsTile:(Tile*)tile inside:(BOOL*)inside
{
  insist (tile && inside);
  insist (self != tile);
  
  *inside = NO;
  
  /*first do the easy test*/
  if ([self cannotIntersectTile: tile])
    return NO;
  
  /*they might intersect. do the work to find out. first check for the
   one inside the other case*/
  if (polygon_inside (points, NUM_POINTS, tile->points, NUM_POINTS) ||
      polygon_inside (tile->points, NUM_POINTS, points, NUM_POINTS))
  {
    *inside = YES;
    return YES;
  }
  
  /*now check for a regular intersection*/
  return polygon_intersection (points, NUM_POINTS, tile->points, NUM_POINTS, inside);
}

- (void) drawOutline:(CGContextRef) context scale:(CGFloat)scale shadow:(BOOL)shadow
{
  /*now draw outline*/
  
  CGContextBeginPath (context);
  CGContextMoveToPoint (context, scale*points [0].x, scale*points [0].y);
  
  for (int i = 0; i < NUM_POINTS; i++)
  {
    int n = (i + 1) % NUM_POINTS;
    CGContextAddLineToPoint (context, scale*points [n].x, scale*points [n].y);
  }
  
  CGContextSetRGBStrokeColor (context, 0, 0, 0, 1);
  CGContextSetLineWidth(context, 1.0);
  CGContextStrokePath(context);//closes path
}

- (void) drawFrame:(CGContextRef) context scale:(CGFloat)scale
{  
  /*draw translucent inside of frame*/
  CGContextSaveGState (context);

  CGContextSetAlpha (context, FRAME_ALPHA);
  CGContextBeginPath (context);
  CGContextMoveToPoint (context, scale*frame [0].x, scale*frame [0].y);
  
  for (int i = 0; i < NUM_FRAME_POINTS; i++)
  {
    int n = (i + 1) % NUM_FRAME_POINTS;
    CGContextAddLineToPoint (context, scale*frame [n].x, scale*frame [n].y);
  }
  
  CGContextSetFillColorWithColor(context, [[UIColor grayColor] CGColor]);
  CGContextFillPath(context);//closes path
  
  /*draw outline of frame*/  
  CGContextBeginPath (context);
  
  CGContextMoveToPoint (context, scale*frame [0].x, scale*frame [0].y);
  
  for (int i = 0; i < NUM_FRAME_POINTS; i++)
  {
    int n = (i + 1) % NUM_FRAME_POINTS;
    CGContextAddLineToPoint (context, scale*frame [n].x, scale*frame [n].y);
  }
  
  CGContextSetRGBStrokeColor (context, 0, 0, 0, 1);
  CGContextSetLineWidth(context, 2.0);
  CGContextStrokePath(context);//closes path
  CGContextRestoreGState (context);
}

- (void) draw:(CGContextRef) context scale:(CGFloat)scale shadow:(BOOL)shadow
{
  /*draw frame*/
  if (framed)
    [self drawFrame:context scale:scale];
  
  /*draw inside of tile*/
  CGContextBeginPath (context);
  CGContextMoveToPoint (context, scale*points [0].x, scale*points [0].y);
  
  for (int i = 0; i < NUM_POINTS; i++)
  {
    int n = (i + 1) % NUM_POINTS;
    CGContextAddLineToPoint (context, scale*points [n].x, scale*points [n].y);
  }
  
  CGContextSetFillColorWithColor(context, [color CGColor]);
  
  CGContextFillPath(context);//closes path
  
  if (shadow)
    CGContextSetShadow (context, CGSizeMake(4,-4), 6);
  else
    CGContextSetShadow (context, CGSizeMake(0, 0), 0);
  
  [self drawOutline:context scale:scale shadow:shadow];
  
  CGContextSetShadow (context, CGSizeMake(0, 0), 0);
}

- (void) setColor:(UIColor*)aColor
{
  insist (aColor);
  [color release];
  color = [aColor retain];
}

- (CGPoint*) rotatablePointNearPoint:(CGPoint)point
{
  insist (0);
  return 0;
}

- (void) flip
{
  for (int i = 0; i < NUM_POINTS; i++)
    points [i].y *= -1.0;
  flipped = !flipped;
}

- (CGPoint*)shape
{
  insist (0);
  return 0;
}

- (int) type
{
  insist (0);
  return 0;
}

- (void) coincideWith:(Tile*)tile
{
  insist (tile);
  insist ([self type] == [tile type]);
  memcpy (points, tile->points, sizeof (points));
  rotation = tile->rotation;
  origin = tile->origin;
}

- (BOOL) joinTo:(Tile*)tile
{
  insist (0);
  return 0;
}

- (BOOL) joinTo:(Tile*)him myA:(int)myAi hisA:(int)hisAi myB:(int)myBi hisB:(int)hisBi angle:(double)angle
{
  CGPoint myA = points [myAi];
  CGPoint myB = points [myBi];
  CGPoint hisA = him->points [hisAi];
  CGPoint hisB = him->points [hisBi];
  
  insist (myAi != myBi && hisAi != hisBi);
  insist (![self joined:him]);
  
  if (distance (myA, hisA) <= JOIN_PROXIMITY && distance (myB, hisB) <= JOIN_PROXIMITY)
  {    
    /*if we are already connected to someone we can't move anywhere*/
    if ([self islanded])
    {
      double dx, dy;
      
      /*rotate to line up with him. first make all the
       angles positive so we can compare them*/
      CGFloat my_rotation = normalize_angle (rotation);
      CGFloat his_rotation = normalize_angle (him->rotation);
      angle = normalize_angle (angle);
      CGFloat r1 = his_rotation + angle;
      CGFloat r2 = his_rotation - angle;
      
      if (fabs (my_rotation - r1) < fabs (my_rotation - r2))
        rotation = r1;
      rotation = r2;
      
      [self rotateBy:0];
      
      /*get my new offset from him*/
      myA = points [myAi];
      dx = hisA.x - myA.x;
      dy = hisA.y - myA.y;
      
      /*now it is safe to translate myself onto his segment*/
      
      [self moveByX:dx byY:dy];
      //NSLog (@"(%f, %f) == (%f, %f)", points [myAi].x, points [myAi].y, him->points [hisAi].x, him->points [hisAi].y);
      //NSLog (@"(%f, %f) == (%f, %f)", points [myBi].x, points [myBi].y, him->points [hisBi].x, him->points [hisBi].y);
      //insist (points [myAi].x == him->points [hisAi].x && points [myAi].y == him->points [hisAi].y);
      //insist (points [myBi].x == him->points [hisBi].x && points [myBi].y == him->points [hisBi].y);
    }
    /*get the neighbor indexes which are the low numbered ends of each line segment
     except for the last segment since we are a closed loop.*/
    
    int myIndex, hisIndex;
    if (myAi == NUM_POINTS-1 && myBi == 0 || myAi == 0 && myBi == NUM_POINTS-1)
      myIndex = NUM_POINTS-1;
    else
      myIndex = (myAi < myBi ? myAi : myBi);
    if (hisAi == NUM_POINTS-1 && hisBi == 0 || hisAi == 0 && hisBi == NUM_POINTS-1)
      hisIndex = NUM_POINTS-1;
    else
      hisIndex = (hisAi < hisBi ? hisAi : hisBi);
    
    insist (!neighbors [myIndex] || neighbors[myIndex] == him);
    insist (!him->neighbors [hisIndex] || him->neighbors[hisIndex] == self);
    insist (!neighbors[myIndex] && !him->neighbors[hisIndex]);

    neighbors [myIndex] = him;
    him->neighbors[hisIndex] = self;
    
    return YES;
  }
  return NO;
}

/*make sure rotation is a multiple of PHI/5*/
- (void) roundRotation
{
  rotation = floorf (rotation / (M_PI / 10.0) + 0.5) * (M_PI / 10.0);
  [self rotateBy:0.0];
}


/*return yes if i am joined to him*/
- (BOOL) joined:(Tile*)him
{
  for (int i = 0; i < NUM_POINTS; i++)
  {
    if (neighbors [i] == him)
      return YES;
  }
  return NO;
}

/*get any neighbor. we don't care which one*/
- (Tile*) anyNeighbor
{
  for (int i = 0; i < NUM_POINTS; i++)
  {
    if (neighbors [i])
      return neighbors [i];
  }
  return nil;
}

- (Tile*) neighbor:(int)which
{
  insist (which >= 0 && which < NUM_POINTS);
  return neighbors [which];
}

- (int) numNeigbors;
{
  int num = 0;
  for (int i = 0; i < NUM_POINTS; i++)
  {
    if (neighbors[i])
      num++;
  }
  return num;
}

- (void) unjoin:(Tile*)him
{
  /*find the 2 neighbor indexes*/
  int myIndex, hisIndex;
  for (myIndex = 0; myIndex < NUM_POINTS && neighbors [myIndex] != him; myIndex++);
  for (hisIndex = 0; hisIndex < NUM_POINTS && him->neighbors [hisIndex] != self; hisIndex++);
  
  insist (myIndex >= 0 && myIndex < NUM_POINTS);
  insist (hisIndex >= 0 && hisIndex < NUM_POINTS);
  
  neighbors [myIndex] = him->neighbors[hisIndex] = 0;
}

/*unjoin from everyone i'm joined with*/
- (void) unjoin
{
  for (int i = 0; i < NUM_POINTS; i++)
  {
    Tile*other = neighbors [i];
    if (other)
    {
      insist ([other joined:self]);
      [self unjoin:other];
    }
  }
}

/*get a point that's on the line segemnt a-b pretty close to a but not close to b*/
- (CGPoint) segmentPointFromA:(CGPoint)a towardsB:(CGPoint)b
{
  CGFloat dx = (b.x - a.x);
  CGFloat dy = (b.y - a.y);
  CGFloat diry = dy > 0 ? 1.0 : -1.0;
  CGFloat dirx = dx > 0 ? 1.0 : -1.0;
  
  /*special case infinite slope*/
  if (dx == 0.0)
  { 
    return CGPointMake (a.x, a.y + diry * SMALL_PIECE_OF_SEGMENT);
  }
  
  CGFloat w = atan2 (fabs (dy), fabs (dx));
  CGFloat xx = SMALL_PIECE_OF_SEGMENT * cos (w);
  CGFloat yy = SMALL_PIECE_OF_SEGMENT * sin (w);
  
  return CGPointMake (a.x + dirx * xx, a.y + diry * yy);
}


/*yes if this tile is right next to me and not joined.*/
- (BOOL) abuts:(Tile*)other
{
  /*only test tiles that are close together*/
  if ([self cannotAbutTile:other])
    return NO;

  /*for each of my unjoined segments see if they line up to one of his*/
   
  for (int i = 0; i < NUM_POINTS; i++)
  {
    int myA = i;
    int myB = (i+1) % NUM_POINTS;
    
    for (int j = 0; j < NUM_POINTS; j++)
    {
      int hisA = j;
      int hisB = (j+1) % NUM_POINTS;
      
      /*see if the segments can line up (either way)*/
      if ((distance (points [myA], other->points [hisA]) <= ABUT_PROXIMITY && distance (points [myB], other->points [hisB]) <= ABUT_PROXIMITY) ||
          (distance (points [myA], other->points [hisB]) <= ABUT_PROXIMITY && distance (points [myB], other->points [hisA]) <= ABUT_PROXIMITY))
      {
        if (neighbors [myA] != other || other->neighbors [hisA] != self)
          return YES;
      }
      
      /*look for segments lined up that are not the same length. this is also an illegal abutment. we have
        to do 4 combinations (not 2) because the lines don't have to meet at both ends.*/
       if ((distance (points [myA], other->points [hisA]) <= ABUT_PROXIMITY))
       {
         CGPoint myC = [self segmentPointFromA:points [myA] towardsB:points [myB]];
         CGPoint hisC = [self segmentPointFromA:other->points [hisA] towardsB:other->points [hisB]];
         
         if (distance (myC, hisC) <= ABUT_PROXIMITY)
         {
           if (neighbors [myA] != other || other->neighbors [hisA] != self)
             return YES;
         }
       }
      /*look for segments lined up that are not the same length. this is also an illegal abutment*/
      if ((distance (points [myA], other->points [hisB]) <= ABUT_PROXIMITY))
      {
        CGPoint myC = [self segmentPointFromA:points [myA] towardsB:points [myB]];
        CGPoint hisC = [self segmentPointFromA:other->points [hisB] towardsB:other->points [hisA]];
        
        if (distance (myC, hisC) <= ABUT_PROXIMITY)
        {
          if (neighbors [myA] != other || other->neighbors [hisA] != self)
            return YES;
        }
      }
      if ((distance (points [myB], other->points [hisA]) <= ABUT_PROXIMITY))
      {
        CGPoint myC = [self segmentPointFromA:points [myB] towardsB:points [myA]];
        CGPoint hisC = [self segmentPointFromA:other->points [hisA] towardsB:other->points [hisB]];
        
        if (distance (myC, hisC) <= ABUT_PROXIMITY)
        {
          if (neighbors [myA] != other || other->neighbors [hisA] != self)
            return YES;
        }
      }
      /*look for segments lined up that are not the same length. this is also an illegal abutment*/
      if ((distance (points [myB], other->points [hisB]) <= ABUT_PROXIMITY))
      {
        CGPoint myC = [self segmentPointFromA:points [myB] towardsB:points [myA]];
        CGPoint hisC = [self segmentPointFromA:other->points [hisB] towardsB:other->points [hisA]];
        
        if (distance (myC, hisC) <= ABUT_PROXIMITY)
        {
          if (neighbors [myA] != other || other->neighbors [hisA] != self)
            return YES;
        }
      }
    }
  }
  return NO;
}

- (CGPoint) origin
{
  return origin;
}

- (void) reset
{
  rotation = 0.0;
  [self moveToX:0.0 toY:0.0];
}

- (void) setShowArcs:(BOOL)b
{
  showArcs = b;
}

- (void) setFramed:(BOOL)aFramed;
{
  framed = aFramed;
  if (framed) [self updateFrame];
}

- (BOOL)framed
{
  return framed;
}


+ (Tile*) readFromFile:(FILE*)fp
{
  insist (fp);
  int r;  

  CGPoint origin;
  CGFloat rotation;
  int type;
  unsigned color;
  
  r = fscanf (fp, "%d %f %f %fn", &type, &origin.x, &origin.y, &rotation);
  insist (r == 4 && type >= 0 && type < NUM_TILES);
  
  r = fscanf (fp, "%u\n", &color);
  insist (r == 1);
  UIColor*c = [Tile colorFromUnsigned:color];
  insist (c);
  
  Tile*tile = [Tile tileOfType:type color:c];

  insist (tile);
  [tile moveToX:origin.x toY:origin.y];
  [tile rotateBy:rotation];
  
  /*for now store the array indexes*/
  for (int i = 0; i < NUM_POINTS; i++)
  {
    int n;
    r = fscanf (fp, "%d\n", &n);
    insist (r == 1);
    tile->neighbors [i] = (void*)n;
  }
  
  return tile;
}

- (void)setNeighborIndexesFromArray:(NSArray*)array
{
  insist (self && array);
  for (int i = 0; i < NUM_POINTS; i++)
  {
    int n = (int) neighbors [i];
    if (n < 0)
      neighbors [i] = nil;
    else
    {
      insist (n >= 0 && n < [array count]);
      neighbors [i] = [array objectAtIndex:n];
    }  
  }
}
- (void)writeToFile:(FILE*)fp array:(NSArray*)array;
{
  insist (fp && array && color);
  fprintf (fp, "%d %f %f %f\n", [self type], origin.x, origin.y, rotation);
  fprintf (fp, "%u\n", [Tile numberFromColor:color]);

  for (int i = 0; i < NUM_POINTS; i++)
  {
    Tile*tile = neighbors [i];
    fprintf (fp, "%d\n", tile ? [array indexOfObject: tile] : -1);
  }
}

- (UIColor*)getColor
{
  return color;
}
- (void) dump
{
  NSLog(@"tile %p, type is %d\n", self, [self type]);
  for (int i = 0; i < NUM_POINTS; i++)
    NSLog(@"(%f, %f)\n", points [i].x, points [i].y);
  NSLog (@"\n");
}
@end
