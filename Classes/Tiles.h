//
//  Tiles.h
//  Penrose
//
//  Created by finucane on 12/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tile.h"

@interface Kite : Tile
{
  
}

- (void) draw:(CGContextRef) context scale:(CGFloat)scale shadow:(BOOL)shadow;
- (CGPoint*) shape;
- (CGPoint*) rotatablePointNearPoint:(CGPoint)point;
- (int)type;
- (BOOL) joinTo:(Tile*)tile;
@end

@interface Dart : Tile
{
}

- (void) draw:(CGContextRef) context scale:(CGFloat)scale shadow:(BOOL)shadow;
- (CGPoint*) shape;
- (CGPoint*) rotatablePointNearPoint:(CGPoint)point;
- (int)type;
- (BOOL) joinTo:(Tile*)tile;
@end


@interface Thin : Tile
{
}

- (void) draw:(CGContextRef) context scale:(CGFloat)scale shadow:(BOOL)shadow;
- (CGPoint*) shape;
- (CGPoint*) rotatablePointNearPoint:(CGPoint)point;
- (BOOL) joinTo:(Tile*)tile;
- (int)type;
@end

@interface Thick : Tile
{
}

- (void) draw:(CGContextRef) context scale:(CGFloat)scale shadow:(BOOL)shadow;
- (CGPoint*) shape;
- (CGPoint*) rotatablePointNearPoint:(CGPoint)point;
- (int)type;
- (BOOL) joinTo:(Tile*)tile;
@end
