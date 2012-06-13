//
//  Plane.h
//  Penrose
//
//  Created by finucane on 12/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tile.h"


enum
{
  CURSOR,
  PAINT,
  DELETE
};

@interface Plane : UIView
{
  NSMutableDictionary*sections;
  NSMutableArray*laidTiles;
  NSMutableArray*visibleTiles;
  Tile*workingTile;
  Tile*selectedTile;
  CGRect visibleRect;
  int touchState;
  int userState;
  int currentTile;
  CGPoint touchLocation;
  NSTimeInterval touchTime;
  CGPoint*rotationPoint; //original point for rotation in plane units
  id appDelegate;
  Tile*helperTiles[4];
  CGImageRef saveImageRef;
  CGContextRef saveContext;
  UIImage*saveImage;
  CGLayerRef layerRef;
  BOOL layerIsDirty;
  BOOL testing;
  Tile*killedTile;
  Tile*killedNeighbor;
  Tile*coloredTile;
  UIColor*coloredTileColor;
}

- (id)initWithFrame:(CGRect)aRect appDelegate:(id)appDelegate;
- (void)reset;
- (void)setUserState:(int)state;
- (BOOL)canDrop:(int)type atPoint:(CGPoint)point;
- (void)drop:(int)type withColor:(UIColor*)color atPoint:(CGPoint)point redraw:(BOOL)redraw;
- (void) writeToFile:(NSString*)filename;
- (BOOL) readFromFile:(NSString*)filename;
- (BOOL) saveWithLines:(BOOL)withLines;
- (void) test;
- (BOOL)justKilled;
- (void) undoKill;
@end
