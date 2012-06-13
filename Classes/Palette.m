//
//  Palette.m
//  Penrose
//
//  Created by finucane on 1/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Palette.h"
#import "Tile.h"
#import "insist.h"

@implementation Palette

- (id) init
{
  self = [super init];
  insist (self);
  
  colors [0] = [[UIColor redColor] retain];
  colors [1] = [[UIColor greenColor] retain];
  colors [2] = [[UIColor magentaColor] retain];
  colors [3] = [[UIColor orangeColor] retain];
  colors [4] = [[UIColor blueColor] retain];
  
  return self;
}

- (id) initFromFile:(FILE*)fp
{
  self = [super init];
  insist (self);
  
  insist (fp);
  
  for (int i = 0; i < NUM_PALETTE_COLORS; i++)
  {
    unsigned n;
    int r = fscanf (fp, "%x", &n);
    insist (r);
    colors [i] = [[Tile colorFromUnsigned:n] retain];
    insist (colors [i]);
  }
  return self;
}

- (void) write:(FILE*)fp
{
  insist (fp);
  for (int i = 0; i < NUM_PALETTE_COLORS; i++)
    fprintf (fp, "%x ", [Tile numberFromColor:colors [i]]);
  fprintf (fp, "\n");
}

- (void) dealloc
{
  for (int i = 0; i < NUM_PALETTE_COLORS; i++)
  {
    if (colors [i])
      [colors [i] release];
  }
  [super dealloc];
}

- (UIColor*) colorAtIndex:(int)index
{
  insist (index >= 0 && index < NUM_PALETTE_COLORS);
  return colors [index];
}

- (void) setColor:(UIColor*)color atIndex:(int)index
{
  insist (color);
  insist (index >= 0 && index < NUM_PALETTE_COLORS);
  [colors [index] release];
  colors [index] = [color retain];
}
@end
