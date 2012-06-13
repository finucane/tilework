//
//  ImageMaker.m
//  Penrose
//
//  Created by finucane on 12/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ImageMaker.h"
#import "geometry.h"
#import "insist.h"

#define EDGE_PIXELS 60
#define SQUARE_INSET 20
#define BEVEL_INSET 10

#define array_size(a)(sizeof(a)/sizeof(*a))
static CGPoint kTopLeftPoints [] =
{
{EDGE_PIXELS - BEVEL_INSET, EDGE_PIXELS - BEVEL_INSET},
{0.0 + BEVEL_INSET, EDGE_PIXELS - BEVEL_INSET},
{0.0 + BEVEL_INSET, EDGE_PIXELS - BEVEL_INSET},
{0.0 + BEVEL_INSET, 0.0 + BEVEL_INSET}
};

static CGPoint kBottomRightPoints [] =
{
{0.0 + BEVEL_INSET , 0.0 + BEVEL_INSET},
{EDGE_PIXELS - BEVEL_INSET, 0.0 + BEVEL_INSET},
{EDGE_PIXELS - BEVEL_INSET, 0.0 + BEVEL_INSET},
{EDGE_PIXELS - BEVEL_INSET, EDGE_PIXELS - BEVEL_INSET}
};

@implementation ImageMaker

-(id) init
{
  self = [super init];
  insist (self);
  
  /*make our tiles that we keep around to draw into images with*/
  dart = [[Dart alloc] initWithColor:[UIColor blackColor]];
  kite = [[Kite alloc] initWithColor:[UIColor blackColor]];
  thin = [[Thin alloc] initWithColor:[UIColor blackColor]];
  thick = [[Thick alloc] initWithColor:[UIColor blackColor]];
  
  /*flip them vertically because off screen images are upside down. rotation
    doesn't help, we need to flip*/
  [dart flip];
  [kite flip];
  [thin flip];
  [thick flip];
  
  [kite setShowArcs:YES];
  [dart setShowArcs:YES];
  [thin setShowArcs:YES];
  [thick setShowArcs:YES];
  
  return self;
}

- (void) dealloc
{
  [dart release];
  [kite release];
  [thin release];
  [thick release];
  [super dealloc];
}

- (CGContextRef) createContext:(int)edge
{
  /*create the context*/
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB ();
  insist (colorSpace);
  
  void*bitmapData = malloc (edge * edge * 4);
  insist (bitmapData);

  CGContextRef context = CGBitmapContextCreate (bitmapData, edge, edge, 8, edge * 4, colorSpace, kCGImageAlphaPremultipliedLast);
  insist (context);
  CGColorSpaceRelease (colorSpace);
  
  /*turn on anti-aliasing*/
  CGContextSetShouldAntialias (context, YES);
  CGContextSetAllowsAntialiasing (context, YES);
  
  /*make the background transparent*/
  CGContextClearRect (context, CGRectMake (0, 0, edge, edge));
  
  return context;
}


- (void) drawBevel:(CGContextRef)context
{
  /*draw the darker background*/
  CGContextSetFillColorWithColor (context, [[UIColor lightGrayColor] CGColor]);
  CGRect background = CGRectMake (0 + BEVEL_INSET, 0 + BEVEL_INSET, EDGE_PIXELS - BEVEL_INSET * 2, EDGE_PIXELS - BEVEL_INSET * 2);
  CGContextFillRect (context, background);
    
  /*now the fucking bevel to hopefully make this thing look pressed in*/
  CGContextSetLineWidth(context, 1.0);
  CGContextSetRGBStrokeColor (context, 0, 0, 0, 1);
  CGContextStrokeLineSegments (context, kTopLeftPoints, array_size (kTopLeftPoints));
  CGContextSetRGBStrokeColor (context, 1, 1, 1, 1);
  CGContextStrokeLineSegments (context, kBottomRightPoints, array_size (kTopLeftPoints));
}

- (UIImage*) makeTileImage:(Tile*)tile scale:(CGFloat) scale color:(UIColor*)color selected:(BOOL)selected autoSize:(BOOL)autoSize shadow:(BOOL)shadow framed:(BOOL)framed
{
  insist (self && tile);
  
  /*set the color of the helper tile*/
  [tile setColor:color];
  [tile setFramed:framed];
  int edge = autoSize ?  4 * PHI * scale : EDGE_PIXELS;
  
  if (framed)
    edge = [Tile frameEdge] * scale;
    
  /*get a new context*/
  CGContextRef context = [self createContext:edge];
  insist (context);
  
  if (selected)
  {
    insist (!autoSize);
    [self drawBevel:context];
  }
  
  /*make the origin in the center of the context and set the scale so drawing in the unit
   coordinate system fits into the context*/
  CGContextTranslateCTM (context, edge/2.0, edge/2.0);
  
  /*draw the tile*/
  [tile draw:context scale:scale shadow:shadow];
  
  CGImageRef imageRef = CGBitmapContextCreateImage (context);
  insist (imageRef);
  
  UIImage*image = [UIImage imageWithCGImage:imageRef];
  insist (image);

  /*free the cg stuff*/
  CGImageRelease (imageRef);
  char*p = CGBitmapContextGetData (context);
  CGContextRelease (context);
  if (p) free (p);

  return image;
}

- (UIImage*)tileImageOfType:(int)type color:(UIColor*)color scale:(CGFloat)scale selected:(BOOL)selected autoSize:(BOOL)autoSize shadow:(BOOL)shadow framed:(BOOL)framed
{
  Tile*tile;
  if (type == DART) tile = dart;
  else if (type == KITE) tile = kite;
  else if (type == THIN) tile = thin;
  else tile = thick;
  
  return [self makeTileImage:tile scale:scale color:color selected:selected autoSize:autoSize shadow:shadow framed:framed];
}

- (UIImage*)squareImage:(UIColor*)color selected:(BOOL)selected
{
  /*get a new context*/
  CGContextRef context = [self createContext:EDGE_PIXELS];
  insist (context);
  
  if (selected)
    [self drawBevel:context];
  
  /*draw the colored square*/
  CGContextSetFillColorWithColor (context, [color CGColor]);
  CGRect square = CGRectMake (SQUARE_INSET, SQUARE_INSET, EDGE_PIXELS - SQUARE_INSET*2, EDGE_PIXELS - SQUARE_INSET*2);
  CGContextFillRect (context, square);

  /*draw the outline*/
  CGContextSetRGBStrokeColor (context, 0, 0, 0, 1);
  CGContextSetLineWidth(context, 1.0);
  CGContextStrokeRect (context, square);
  
  CGImageRef imageRef = CGBitmapContextCreateImage (context);
  insist (imageRef);
  
  UIImage*image = [UIImage imageWithCGImage:imageRef];
  insist (image);

  /*free the cg stuff*/
  CGImageRelease (imageRef);
  char*p = CGBitmapContextGetData (context);
  CGContextRelease (context);
  if (p) free (p);
 
  return image;  
}

- (UIImage*)xImageSelected:(BOOL)selected
{
  /*get a new context*/
  CGContextRef context = [self createContext:EDGE_PIXELS];
  insist (context);
  
  if (selected)
    [self drawBevel:context];
  
  /*draw 2 crossed lines in red*/

  CGContextBeginPath (context);

  CGContextSetRGBStrokeColor (context, 1, 0, 0, 1);
  CGContextSetLineWidth(context, 5.0);
  
  CGContextMoveToPoint (context, SQUARE_INSET, SQUARE_INSET);
  CGContextAddLineToPoint (context, EDGE_PIXELS - SQUARE_INSET, EDGE_PIXELS - SQUARE_INSET);
  CGContextMoveToPoint (context, SQUARE_INSET, EDGE_PIXELS - SQUARE_INSET);
  CGContextAddLineToPoint (context, EDGE_PIXELS - SQUARE_INSET, SQUARE_INSET);
  CGContextStrokePath(context);//closes path
  
  CGImageRef imageRef = CGBitmapContextCreateImage (context);
  insist (imageRef);
  
  UIImage*image = [UIImage imageWithCGImage:imageRef];
  insist (image);
  
  /*free the cg stuff*/
  CGImageRelease (imageRef);
  char*p = CGBitmapContextGetData (context);
  CGContextRelease (context);
  if (p) free (p);
  
  return image;  
}

@end
