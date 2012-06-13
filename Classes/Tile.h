//
//  Tile.h
//  Penrose
//
//  Created by David Finucane on 12/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define NUM_POINTS 4
#define NUM_FRAME_POINTS 4
#define TRANSLUCENT 1.0

enum
{
  DART = 0,
  KITE,
  THICK,
  THIN,
  NUM_TILES
};


@interface Tile : NSObject
{
  CGPoint points [NUM_POINTS];
  CGPoint frame [NUM_FRAME_POINTS];
  Tile*neighbors [NUM_POINTS];
  CGPoint origin;
  CGFloat rotation;
  UIColor*color;
  BOOL flipped;
  BOOL framed;
  BOOL showArcs;
}

+ (void) initialize;
+ (void) setScale:(CGFloat)scale;
+ (CGFloat) scale;
+ (CGPoint*) dartPoints;
+ (CGPoint*) kitePoints;
+ (CGPoint*) thinPoints;
+ (CGPoint*) thickPoints;
+ (BOOL) enableOrnaments;
+ (void) setEnableOrnaments:(BOOL)b;
+ (unsigned) numberFromColor:(UIColor*)color;
+ (UIColor*)colorFromUnsigned:(unsigned)n;
+ (Tile*) readFromFile:(FILE*)fp;
+ (Tile*)tileOfType:(int)type color:(UIColor*)color;
+ (CGFloat) frameEdge;

- (id) initWithColor:(UIColor*) aColor;
- (void) moveToX:(CGFloat)x toY:(CGFloat)y;
- (void) moveByX:(CGFloat)x byY:(CGFloat)y;
- (void) rotateBy:(CGFloat)radians;
- (void) draw:(CGContextRef) context scale:(CGFloat)scale shadow:(BOOL)shadow;
- (void) drawOutline:(CGContextRef) context scale:(CGFloat)scale shadow:(BOOL)shadow;
- (CGPoint*)shape;
- (BOOL) isAtLeastPartiallyInsideRect:(CGRect)rect;
- (CGFloat) getRotationFromPoint:(CGPoint)from toPoint:(CGPoint)to;
- (BOOL) cannotIntersectTile:(Tile*)tile;
- (BOOL) cannotAbutTile:(Tile*)tile;
- (BOOL) cannotIntersectPoint:(CGPoint)point;
- (CGPoint*) rotatablePointNearPoint:(CGPoint)point;
- (CGPoint*) framedRotatablePointNearPoint:(CGPoint)point;
- (BOOL) containsPoint:(CGPoint)point;
- (BOOL) framedContainsPoint:(CGPoint)point;
- (BOOL) intersectsTile:(Tile*)tile inside:(BOOL*)inside;
- (BOOL) landLocked;
- (BOOL) islanded;
- (void) setColor:(UIColor*)aColor;
- (void) flip;
- (int) type;
- (void) coincideWith:(Tile*)tile;
- (void) reset;
- (void) setShowArcs:(BOOL)b;
- (BOOL) joinTo:(Tile*)tile;
- (BOOL) joinTo:(Tile*)him myA:(int)myA hisA:(int)hisA myB:(int)myB hisB:(int)hisB angle:(double)angle;
- (BOOL) joined:(Tile*)him;
- (void) unjoin;
- (Tile*) neighbor:(int)which;
- (int) numNeigbors;
- (CGPoint) origin;
- (void) setFramed:(BOOL)aFramed;
- (BOOL) abuts:(Tile*)other;
- (BOOL)framed;
- (void)writeToFile:(FILE*)fp array:(NSArray*)array;
- (void) setNeighborIndexesFromArray:(NSArray*)array;
- (void) roundRotation;
- (UIColor*)getColor;
- (void) updateFrame;
- (void) dump;
- (Tile*)anyNeighbor;
@end
