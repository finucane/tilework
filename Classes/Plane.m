//
//  Plane.m
//  Penrose
//
//  Created by finucane on 12/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Plane.h"
#import "PenroseAppDelegate.h"
#import "insist.h"
#import "geometry.h"

@implementation Plane
#define SAVE_SCALE 15

#define MIN_SCALE 5
#define MAX_SCALE 100

#define ZOOM_FACTOR 1.10
#define SECTION_EDGE 10
#define VISIBLE_RECT_SLOP PHI

#define SMALLEST_ANGLE (M_PI/180)
#define SMALLEST_DISTANCE (PHI/100.0)
#define MAX_PHOTO_BYTES (1024 * 1024 * 16)

//#define SHOW_TOUCH

static NSString*assertion_msg = nil;
void report_assertion (NSString*msg)
{
  assertion_msg = [msg retain];
}

enum
{
  NOTHING,
  DOWN,
  SCROLLING,
  MOVING_TILE,
  PINCHING,
  MOVING_USELESSLY,
  WAITING_FOR_TOUCHES_TO_END
};

- (CGPoint) windowPointToPlanePoint:(CGPoint)point
{
  CGFloat scale = [Tile scale];
  CGPoint p;
  p.x = point.x / scale + visibleRect.origin.x;
  p.y = point.y / scale + visibleRect.origin.y;
  return p;
}

/*return section key for point which is in plane coordinates*/
- (NSNumber*)keyForPoint:(CGPoint)p
{
  int x = (p.x / SECTION_EDGE);
  int y = (p.y / SECTION_EDGE);
  unsigned key = ((x & 0xffff) | ((y << 16) & 0x0000ffff));
  return [NSNumber numberWithUnsignedInteger: key];
}

- (Tile*)getFramedTile
{
  /*the working tile is always framed*/
  if (workingTile) return workingTile;

  /*so is a single center tile*/
  if ([laidTiles count] == 1)
  {
    Tile*tile = [laidTiles objectAtIndex:0];
    [tile setFramed:YES];
    return [laidTiles objectAtIndex:0];
  }
  return nil;
}

- (void) forgetKilled
{
  if (killedTile)
  {
    [killedTile release];
    killedTile = nil;
  }
  killedNeighbor = nil;

  if (coloredTile)
  {
    [coloredTile release];
    coloredTile = nil;
    [coloredTileColor release];
    coloredTileColor = nil;
  }
}

- (void) rememberKilled:(Tile*)tile
{
  insist (tile);
  /*forget any previous kill*/
  [self forgetKilled];
  
  /*remember tile that's being killed*/
  killedTile = [tile retain];
  killedNeighbor = [tile anyNeighbor];//might be nil
}

/*add the tile to the laid tiles collection and also to the appropriate section*/
- (void) addToLaidTiles:(Tile*)tile
{
  insist (tile && sections);
  
  /*add it to the laid tiles*/
  [laidTiles addObject:tile];
  
  /*get section key for tile*/
  NSNumber*key = [self keyForPoint:[tile origin]];
  
  /*see if we have a section for this tile already*/
  NSMutableArray*section = [sections objectForKey:key];
  if (!section)
  {
    /*we don't have a section. make it*/
    section = [[[NSMutableArray alloc]init]autorelease];
    [sections setObject:section forKey:key];
  }
  
  /*now just add the tile to the section*/
  [section addObject:tile];
  
  /*unframe the tile*/
  [tile setFramed:NO];
}


/*remove the tile from laid tiles and remove it from its section*/
- (void) removeFromLaidTiles:(Tile*)tile
{
  insist (tile);
  [laidTiles removeObject:tile];
  
  /*get section key for tile*/
  NSNumber*key = [self keyForPoint:[tile origin]];
  
  /*we have a section for this tile already*/
  NSMutableArray*section = [sections objectForKey:key];
  insist (section);
  
  /*just remove the tile from the section*/
  [section removeObject:tile];
}

- (Tile*) tileAtPoint:(CGPoint)point
{
  insist (visibleTiles);
    
  /*check the working tile*/
  if (workingTile && [workingTile framedContainsPoint:point])
    return workingTile;
  
  /*look for a match among the visible tiles*/
  for (int i = 0; i < [visibleTiles count]; i++)
  {
    Tile*tile = [visibleTiles objectAtIndex:i];
    if ([tile framed])
    {
      if ([tile framedContainsPoint:point])
        return tile;
    }
    else if ([tile containsPoint:point])
      return tile;
  }
  return nil;
}

- (Tile*) tileWithRotatablePoint:(CGPoint)point whichPoint:(CGPoint**)whichPoint
{
  insist (visibleTiles && whichPoint);
    
  /*convert the point to plane coordinates*/
  CGPoint*p;
  
  Tile*framedTile = [self getFramedTile];
  if (framedTile && (p = [framedTile framedRotatablePointNearPoint:point]))
  {
    *whichPoint = p;
    return framedTile;
  }
  return nil;
}

/*make a list of all the laidTiles that are inside the visible rect*/
- (void) recomputeVisibleTiles
{
  /*empty the current visible tile set*/
  [visibleTiles removeAllObjects];

#if 1
  /*now scan through all the sections that are intersect the visible rect
    and pick out the tiles that are actually inside the visible rect.*/
   
  /*first pick out all the sections that are visible*/
  NSMutableArray*subsections = [[[NSMutableArray alloc]init]autorelease];
  insist (subsections);
  
  
  /*get a sampling of points it finer intervals than the section edge*/
  CGFloat edge = SECTION_EDGE / 2.0;
  
  CGFloat startx = (visibleRect.origin.x - 2 * SECTION_EDGE);  
  CGFloat starty = (visibleRect.origin.y - 2 * SECTION_EDGE);
  
  for (CGFloat i = startx; i <= (startx + visibleRect.size.width + 2 * SECTION_EDGE); i += edge)
  {
    for (CGFloat j = starty; j <= (starty + visibleRect.size.height + 2 * SECTION_EDGE); j += edge)
    {
      NSNumber*key = [self keyForPoint:CGPointMake (i, j)];
      
      /*see if we have a section for this tile already*/
      NSMutableArray*section = [sections objectForKey:key];

      if (section && ![subsections containsObject:section])
        [subsections addObject:section];
    }
  }
  
  //NSLog (@"%d subsections", [subsections count]);
  
  /*now pick out all the visible tiles*/
  for (int i = 0; i < [subsections count]; i++)
  {
    NSMutableArray*section = [subsections objectAtIndex:i];
    insist (section);
    for (int i = 0; i < [section count]; i++)
    {
      Tile*tile = [section objectAtIndex:i];
      if ([tile isAtLeastPartiallyInsideRect:visibleRect])
        [visibleTiles addObject:tile];
    }        
  }
#else

  for (int i = 0; i < [laidTiles count]; i++)
  {
    Tile*tile = [laidTiles objectAtIndex:i];
    if ([tile isAtLeastPartiallyInsideRect:visibleRect])
      [visibleTiles addObject:tile];
  }
#endif
  if (workingTile) [visibleTiles addObject:workingTile];
}

/*put the visible rect centered at some point in the plane coordinate system*/
- (void) resetVisibleRect:(CGPoint)origin
{
  CGFloat scale = [Tile scale];
  
  visibleRect.size.width = [self bounds].size.width / scale + VISIBLE_RECT_SLOP * 2;
  visibleRect.size.height = [self bounds].size.height / scale + VISIBLE_RECT_SLOP * 2;

  /*rectangle's origins are upper left*/
  visibleRect.origin.x = origin.x - visibleRect.size.width/2.0;
  visibleRect.origin.y = origin.y - visibleRect.size.height/2.0;
  
  /*recompute the visible set*/
  [self recomputeVisibleTiles];
  
  /*force an redraw*/
  [self setNeedsDisplay];
}

- (void) moveVisibleRectByX:(CGFloat)x byY:(CGFloat)y
{
  /*move the visible rectangle. the amounts are already in the
    plane coordinate system units*/
  visibleRect.origin.x += x;
  visibleRect.origin.y += y;

  [self forgetKilled];
  /*recompute the visible set*/
  [self recomputeVisibleTiles];
  [self setNeedsDisplay];
}


- (id) initWithFrame:(CGRect)frame appDelegate:(id)anAppDelegate
{
  if (self = [super initWithFrame:frame])
  {
    appDelegate = [anAppDelegate retain];
    [self setBackgroundColor:[UIColor whiteColor]];
    
    laidTiles = [[NSMutableArray alloc] init];
    insist (laidTiles);
    visibleTiles = [[NSMutableArray alloc] init];
    insist (visibleTiles);
    
    /*make the sections hash table*/
    sections = [[NSMutableDictionary alloc] init];
    insist (sections);
    
    /*make the sections map table. this is a hash table of arrays of tiles so we can get
     at a subsection of the plane quickly*/
    
    workingTile = selectedTile = nil;
    [self resetVisibleRect:CGPointMake (0, 0)];
    
    touchState = NOTHING;
    userState = CURSOR;
    [self setMultipleTouchEnabled:YES];
    
    /*create 4 helper tiles for computing droppability and doing collision tests*/
    helperTiles [DART] = [[Dart alloc] initWithColor:[UIColor blackColor]];
    helperTiles [KITE] = [[Kite alloc] initWithColor:[UIColor blackColor]];
    helperTiles [THIN] = [[Thin alloc] initWithColor:[UIColor blackColor]];
    helperTiles [THICK] = [[Thick alloc] initWithColor:[UIColor blackColor]];
    
    saveImageRef = nil;
    saveContext = 0;
    saveImage = nil;
    testing = NO;
    killedNeighbor = killedTile = nil;
  }
  return self;
}

- (void) reset
{
  insist (laidTiles && visibleTiles);
  testing = NO;
  
  /*get rid of any working tile*/
  if (workingTile)
  {
    [workingTile release];
    workingTile = nil;
  }
  
  /*get rid of the tiles and the visible tile set*/
  [laidTiles removeAllObjects];
  [visibleTiles removeAllObjects];
  [sections removeAllObjects];
  
  rotationPoint = 0;
  
  /*forget any killed tile*/
  [self forgetKilled];
  
  /*reset visible rectangle to be at the center of the plane*/
  [self resetVisibleRect:CGPointMake (0, 0)];
  
  /*recompute set of visible tiles and redraw*/
  layerIsDirty = YES;
  [self recomputeVisibleTiles];
  [self setNeedsDisplay];
}


/*draw the tiles that don't move to a layer. we do this to make refreshing the screen faster*/
- (void)drawLayerWithRect:(CGRect)rect
{
  insist (layerRef);
  CGContextRef context = CGLayerGetContext (layerRef);
  insist (context);

  CGFloat scale = [Tile scale];
  
  CGContextSetAllowsAntialiasing (context, YES);
  CGContextSetShouldAntialias (context, YES);
  
  CGContextSetRGBFillColor (context, 1.0, 1.0, 1.0, 1.0);
  CGContextFillRect (context, rect);
  
  /*save the context because we are going to change the CTM*/
  CGContextSaveGState (context);
  
  CGContextTranslateCTM (context, -visibleRect.origin.x*scale, -visibleRect.origin.y *scale);
  
  Tile*framedTile = [self getFramedTile];
  
  /*now draw all the unframed visible tiles*/
  for (int i = 0; i < [visibleTiles count]; i++)
  {
    Tile*tile = [visibleTiles objectAtIndex:i];
    insist (tile);
    if (tile == framedTile) continue;
    [[visibleTiles objectAtIndex: i] draw:context scale:scale shadow:NO];
  }
  /*undo the transform*/
  CGContextRestoreGState (context);
}

void drawText (CGContextRef context, const char*s)
{  
  CGContextSelectFont (context, "Helvetica", 9, kCGEncodingMacRoman);
  CGContextSetCharacterSpacing (context, 1);
  CGContextSetTextDrawingMode (context, kCGTextFillStroke);
  
  CGContextSetRGBFillColor (context, 0, 0, 0, 1);
  CGContextSetRGBStrokeColor (context, 0, 0, 0, 1);
  
  
  CGAffineTransform transform = CGAffineTransformMake(1.0,0.0, 0.0, -1.0, 0.0, 0.0);
  
  CGContextSetTextMatrix(context, transform);
  
  CGContextShowTextAtPoint (context, 10, 10, s, strlen (s));
}

/*draw whatever's in the visible part of the plane*/
- (void) drawRect:(CGRect) rect
{
  CGContextRef context = UIGraphicsGetCurrentContext ();
  
  /*if we haven't made a layerRef yet do it now*/
  if (!layerRef)
  {
    layerRef = CGLayerCreateWithContext (context, rect.size, nil);
    insist (layerRef);
  }
  CGFloat scale = [Tile scale];
  
  /*if the layer needs redrawing, do that*/
  if (layerIsDirty)
  {
    [self drawLayerWithRect:rect];
    layerIsDirty = NO;
  }
  
  /*draw the layer to the window*/
  CGContextDrawLayerInRect (context, rect, layerRef);
  
  /*save the context because we are going to change the CTM*/
  CGContextSaveGState (context);
  
  CGContextTranslateCTM (context, -visibleRect.origin.x*scale, -visibleRect.origin.y *scale);
  
  Tile*framedTile = [self getFramedTile];

  /*now draw the framed tile, if any*/
  if (framedTile)
    [framedTile draw:context scale:scale shadow:YES];
  
  /*undo the transform*/
  CGContextRestoreGState (context);
  
#ifdef SHOW_TOUCH
  CGContextSetFillColorWithColor(context, [[UIColor grayColor] CGColor]);
  float w = 10;
  CGContextFillEllipseInRect (context, CGRectMake (touchLocation.x-w/2, touchLocation.y-w/2, w, w));
#endif
  
  if (assertion_msg)
  {
    drawText (context, [assertion_msg cStringUsingEncoding:NSUTF8StringEncoding]);
  }
}
  
- (BOOL)canDelete:(Tile*)tile
{
  /*do not allow interior tiles to be deleted*/
  return ![tile landLocked];
}

-(void) touchDown:(UITouch*)touch event:(UIEvent*)event
{
  /*update touch locations and time*/
  insist (touch && event);
  touchLocation = [touch locationInView:self];
  touchTime = [event timestamp];
  
#ifdef SHOW_TOUCH
  [self setNeedsDisplay];
#endif
  /*convert the point to plane coordinates*/
  CGPoint point = [self windowPointToPlanePoint:touchLocation];
  /*do tile selection*/
  
  Tile*tile = [self tileAtPoint:point];
  rotationPoint = 0;
  
  if (tile)
  {    
    switch (userState)
    {
      case CURSOR:
        /*we hit a tile. update the moving color box.*/
        
        /*but we are only allowed to select the framed tile.*/
        if (tile != [self getFramedTile])
          break;

        selectedTile = tile;
        
        /*see if we should rotate*/
        if ([tile framed])
          rotationPoint = [tile framedRotatablePointNearPoint:point];
        
        break;
      case PAINT:
        insist (appDelegate);
        [self forgetKilled];
        coloredTile = [tile retain];
        coloredTileColor = [[tile getColor] retain];

        [tile setColor:[((PenroseAppDelegate*)appDelegate) getSelectedColor]];
        
        /*if we painted the framed tile, then swap colors*/
        if (tile == [self getFramedTile])
        {
          [((PenroseAppDelegate*)appDelegate) swapSelectedColorWithTileType:[tile type]];
          [((PenroseAppDelegate*)appDelegate) deselect];
          userState = NOTHING;
        }
        
        layerIsDirty = YES;
        [self setNeedsDisplay];
        break;
      case DELETE:
        insist (appDelegate);

        if ([self canDelete:tile])
        {
          if (tile != workingTile)
          {
            /*unjoin it*/
            [tile unjoin];
            
            [self rememberKilled:tile];
            /*remove it from the laidTiles array. this releases it*/
            [self removeFromLaidTiles:tile];
          }
          else
          {
            /*we are deleting the working tile*/
            workingTile = nil;
            [tile release];
          }
          [self recomputeVisibleTiles];
          layerIsDirty = YES;
          [self setNeedsDisplay];
          [appDelegate playEraseSound];
          
          /*force user to click on the delete button again*/
      /*    userState = NOTHING;
          [((PenroseAppDelegate*)appDelegate) deselect];*/
        }
        break;
      default:
        insist (0);
        break;
    }
  }
  else if ((tile = [self tileWithRotatablePoint:point whichPoint:&rotationPoint]))
  {
    /*we didn't hit a tile. but we might have clicked down close to
      a corner for rotation*/
    return;
  }
  else
  {
    /*we hit nothing so empty any existing selection*/
    selectedTile = nil;
  }
}    

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  insist (touches && event);
  
  /*a finger came down. deal with it.*/
  UITouch*touch = [[event allTouches] anyObject];
  insist (touch);
  
  switch (touchState)
  {
    case NOTHING:
      /*it is a new touch.*/
      if ([touches count] == 1)
      {
        /*it is just 1 finger so set the touchLocations and update the selection.*/
        [self touchDown:touch event:event];
        touchState = DOWN;
      }
      else if ([touches count] == 2)
      {
        /*2 fingers down, start a pinch*/
        touchState = PINCHING;
      }
      break;
    case DOWN:
      /*a second finger came down while the 1st finger is down and not moving. start a pinch*/
      touchState = PINCHING;
      break;
    default:
      break;
  }
}

/*return yes if the tile collides with any other visible tile, and the collision info*/
- (BOOL) tile:(Tile*)tile collidesWith:(Tile**)otherTile inside:(BOOL*)inside skip:(Tile*)skip;
{
  insist (otherTile && inside);
  *inside = NO;
  
  /*look for a match among the visible tiles*/
  for (int i = 0; i < [visibleTiles count]; i++)
  {
    *otherTile = [visibleTiles objectAtIndex:i];
    if (*otherTile == tile || *otherTile == skip) continue;
    
    if (*otherTile != tile && [tile intersectsTile:*otherTile inside:inside])
      return YES;
  }
  
  return NO;
}


- (BOOL)tile:(Tile*)tile canRotateBy:(CGFloat)radians other:(Tile**)other
{
  insist (tile && other);
  
  /*get a helper tile*/
  Tile*helper = helperTiles [[tile type]];
  insist (helper);
  
  /*move it to exactly where the tile is now*/
  [helper coincideWith:tile];
  
  /*try rotating it*/
  [helper rotateBy:radians];  

  BOOL inside;

  /*it's ok to rotate if the helper doesn't run into anything*/
  if (![self tile:helper collidesWith:other inside:&inside skip:tile])
    return YES;
  
  /*we collided. rotate bit by bit until we hit. bound the loop in case of a
    rounding error causing us near-miss and spin forever*/
  CGFloat delta = radians > 0 ? SMALLEST_ANGLE : -SMALLEST_ANGLE;
  for (int i = 0; i < 360; i++)
  {
    [helper coincideWith:tile];
    [helper rotateBy:delta];
    if ([self tile:helper collidesWith:other inside:&inside skip:tile])
      break;
    [tile rotateBy:delta];
  }
  return NO;
}



- (BOOL)tile:(Tile*)tile canMoveByX:(CGFloat)x byY:(CGFloat)y other:(Tile**)other
{
  insist (tile && other);
  
  /*get a helper tile*/
  Tile*helper = helperTiles [[tile type]];
  insist (helper);
  
  /*move it to exactly where the tile is now*/
  [helper coincideWith:tile];
  
  /*try moving it*/
  [helper moveByX:x byY:y];  

  BOOL inside;
  
  /*it's ok to move if the helper doesn't run into anything*/
  if (![self tile:helper collidesWith:other inside:&inside skip:tile])
    return YES;
  
  insist (tile != *other);
  /*we collided. move bit by bit towards the point that put us at or inside the
   other tile. be wary of an infinite loop.*/
  
  /*get the increments. be careful of the infinite slope case.*/
  CGFloat dx, dy;
  if (x == 0.0)
  {
    dy = y >= 0 ?  SMALLEST_DISTANCE : -SMALLEST_DISTANCE;
    dx = 0;
  }
  else
  {
    dx = x >= 0 ? SMALLEST_DISTANCE : -SMALLEST_DISTANCE;
    dy = dx * (y/x);
  }
  
  /*now just move along the slope until we hit*/

  for (int i = 0; i < 200; i++)
  {
    [helper coincideWith:tile];
    [helper moveByX:dx byY:dy];
    
    if ([self tile:helper collidesWith:other inside:&inside skip:tile])
      break;
    [tile moveByX:dx byY:dy];
  }
  return NO;
}

/*look among all visible tiles for any tile with that is right up against an
 unjoined side of this tile. that means an illegal join happened. it only
 makes sense to call this after joinAny has been called on the tile.*/

- (Tile*) getBadNeighbor:(Tile*)tile
{
  for (int i = 0; i < [visibleTiles count]; i++)
  {
    Tile*other = [visibleTiles objectAtIndex:i];
    if (tile == other || [tile cannotAbutTile:other] || [tile joined:other] || [other landLocked])
      continue;
    
    if ([tile abuts:other])
      return other;
  }
  return nil;
}

- (BOOL)joinAny:(Tile*)tile
{
  /*look among all the visible tiles for a tile we might
    be joined to but without knowing it yet. since a tile can be slid
    into at most 2 other tiles we stop if we find one match. also we have
    enough slop in the visibility test to make sure that we can join a tile
    that is just barely offscreen.*/
  
  for (int i = 0; i < [visibleTiles count]; i++)
  {
    Tile*other = [visibleTiles objectAtIndex:i];
    if (tile == other || [tile cannotIntersectTile:other] || [tile joined:other] || [other landLocked]) continue;
    if ([tile joinTo:other])
      return YES;
  }
  return NO;
}


-(CGRect) computeBounds
{
  /*look at every tile and compute a rectangle around them all*/
  CGFloat minX,minY,maxX,maxY;
  
  for (int i = 0; i < [laidTiles count]; i++)
  {
    Tile*tile = [laidTiles objectAtIndex:i];
    insist (tile);
    CGPoint o = [tile origin];
    if (i == 0)
    {
      minX = o.x - PHI;
      maxX = o.x + PHI;
      minY = o.y - PHI;
      maxY = o.y + PHI;
    }
    else
    {
      if (o.x - PHI < minX)
        minX = o.x - PHI;
      if (o.x + PHI > maxX)
        maxX = o.x + PHI;
      if (o.y - PHI < minY)
        minY = o.y - 2 * PHI;
      if (o.y + PHI > maxY)
        maxY = o.y + 2 * PHI;
    }
  }
  return CGRectMake (minX, minY, maxX-minX, maxY-minY);
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
  insist (touches && event);
  
  /*a finger moved. do something about it*/
  UITouch*touch = [[event allTouches] anyObject];
  insist (touch);
  
  CGPoint location = [touch locationInView:self];
  CGPoint previous = [touch previousLocationInView:self];
  
  CGFloat scale = [Tile scale];
  
  switch (touchState)
  {
    case DOWN:
      /*we had a finger down before, it hasn't moved yet and nothing else
       has happened so that finger must be moving now. if there is a selectedTile
       then we are moving it in some way, otherwise we are scrolling*/
      
      if (userState == CURSOR)
        touchState = selectedTile? MOVING_TILE : SCROLLING;
      else if ((userState == PAINT || userState == DELETE) && !selectedTile)
        touchState = SCROLLING;
      else
        touchState = MOVING_USELESSLY;
      
      /*handle the movement now that we know what it is*/
      [self touchesMoved:touches withEvent:event];
      break;
    case SCROLLING:
      /*move the visibleRect in the opposite direction as the drag*/
      layerIsDirty = YES;
      [self moveVisibleRectByX: (previous.x - location.x) / scale byY: (previous.y - location.y) / scale];
      break;
    case MOVING_TILE:
      /*we have a tile selected. either move it or rotate it*/
      insist (selectedTile);
      [self forgetKilled];

      /*but only if it's the framed tile*/
      if (selectedTile == [self getFramedTile])
      {
        if (rotationPoint)
        {
          /*calcuate the total rotation and rotate.*/
          Tile*other = nil;
          CGPoint p = [self windowPointToPlanePoint:location];
          
          /*if we are moving the finger on top of the tile itself drop the event because
            it causes weirdness*/
          if (![selectedTile containsPoint:p])
          {
            CGFloat radians = [selectedTile getRotationFromPoint:*rotationPoint toPoint:p];
            if ([self tile:selectedTile canRotateBy:radians other:&other])
            {
              [selectedTile rotateBy: radians];
            }
            else
            {
              /*hopefully it rotated close enough to something that a click is in order*/
              [appDelegate playTickSound];
              
              /*if we are off the tile now, abort the rotation because nothing stops
               people from rotating over something*/
              if (![selectedTile containsPoint:[self windowPointToPlanePoint:location]])
                touchState = MOVING_USELESSLY;
            }
          }
        }
        else
        {
          Tile*other = nil;
          CGFloat dx = (location.x - previous.x)/scale;
          CGFloat dy = (location.y - previous.y)/scale;
          
          if ([self tile:selectedTile canMoveByX:dx byY:dy other:&other])
          {
            [selectedTile moveByX:dx byY:dy];
          }
          else
          {
            /*hopefully it moved close enough to something that a click is in order*/
            [appDelegate playTickSound];
            
            /*try to join*/
            insist (other);
            if ([selectedTile joinTo:other])
            {
              /*we joined. we may have joined another at the same time. find it.*/
              if (![self joinAny:selectedTile])
              {
                /*we didn't join a second tile. but we might be right up
                  against an illegal edge match. check for this.*/
                
                if ([self getBadNeighbor:selectedTile])
                {
                  //NSLog (@"bad neighbor");
                  [appDelegate playNegativeSound];      

                  /*the join was illegal. undo it*/
                  [selectedTile unjoin];
                  
                  /*we are so far into nest if's that we just get out of this function from here.*/
                  
                  /*we didn't join. if the touch is now off the tile, abort the movement
                   to prevent the user from dragging the tile through something*/
                  
                  if ([self tileAtPoint:[self windowPointToPlanePoint:location]] != selectedTile)
                    touchState = MOVING_USELESSLY;
                  
                  [self setNeedsDisplay];
                  return;
                }
              }
              
              /*add the tile to the laid tiles*/
              insist (selectedTile == workingTile);
              [self addToLaidTiles:workingTile];
              
              /*for ease of memory management once a tile is laid it's retained only
                by the laidTile array*/
              [workingTile release];
              layerIsDirty = YES;
              touchState = CURSOR;
              workingTile = selectedTile = nil;
              [appDelegate playClickSound];
            }
            else
            {
              /*we didn't join. if the touch is now off the tile, abort the movement
                to prevent the user from dragging the tile through something*/

              if ([self tileAtPoint:[self windowPointToPlanePoint:location]] != selectedTile)
                  touchState = MOVING_USELESSLY;
            }
          }
        }
        [self setNeedsDisplay];
      }
      break;
    case PINCHING:
      
      /*ok. we had a finger move and we have 2 fingers down. adjust the scale up or down depending
       on if our pinch got bigger or smaller*/
      
      /*first we need a couple of points. any 2 will do. and there are at least 2 here.*/
    {
      /*the compiler doesn't like us declaring "array" unless we do it in a new block!*/
      
      NSArray*array = [touches allObjects];
      insist (array);

      /*at least in the simulator you lose half a pinch*/
      
      if ([array count] < 2)
        return;
      
      UITouch*t1 = [array objectAtIndex:0];
      UITouch*t2 = [array objectAtIndex:1];
      CGFloat previousDistance = distance ([t1 previousLocationInView:self], [t2 previousLocationInView:self]);
      CGFloat currentDistance = distance ([t1 locationInView:self], [t2 locationInView:self]);
      
      /*get the current center of the visible rect so we can re-center.
        we have to this because the rectangle origin is upper left.*/
      CGPoint center;
      center.x = visibleRect.origin.x + (visibleRect.size.width / 2.0);
      center.y = visibleRect.origin.y + (visibleRect.size.height / 2.0);

      /*zoom in or out depending on if we are pinching in or out*/
      CGFloat newScale = [Tile scale];
      if (previousDistance < currentDistance)
        newScale *= ZOOM_FACTOR;
      else
        newScale /= ZOOM_FACTOR;
      [self forgetKilled];

      if (testing || (newScale >= MIN_SCALE && newScale <= MAX_SCALE))
      {
        [Tile setScale:newScale];
        Tile*framedTile = [self getFramedTile];
        if (framedTile)
          [framedTile updateFrame];
      }
       
      /*recompute the visible rect centered at the old center. changing the
        visibleRect triggers redrawing.*/
      layerIsDirty = YES;
      [self resetVisibleRect:center];
    }
      break;
    case MOVING_USELESSLY:
      /*do nothing*/
      break;
  }
}

- (int) numTiles
{
  return [laidTiles count] + (workingTile ? 1 : 0);
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  /*if all fingers are up now, go back to doing nothing*/
  if ([touches count] == [[event touchesForView:self] count])
  {
    Tile*framedTile = [self getFramedTile];
    
    /*make sure the center tile is always rotation by a multiple of PI/5.0*/
    if (touchState == MOVING_TILE && rotationPoint && [self numTiles] == 1)
    {
      insist (framedTile && framedTile == selectedTile);
      [framedTile roundRotation];
      [self setNeedsDisplay];
    }
    touchState = NOTHING;
  }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
  /*drop what we were doing*/
  touchState = NOTHING;
}

- (void)setUserState:(int)state
{
  userState = state;
}

- (void)setCurrentTile:(int)tile
{
  currentTile = tile;
}

- (BOOL)canDrop:(int)type atPoint:(CGPoint)point
{
  insist (type >= 0 && type < NUM_TILES);

  if (workingTile) return NO;

  /*convert the point to plane coordinates*/
  point = [self windowPointToPlanePoint:point];
  
  /*get a sample tile for this type*/
  Tile*tile = helperTiles [type];
  insist (tile);
  
  /*make sure it's in an ok state*/
  [tile reset];
  
  /*move the tile to be centered at the point*/
  [tile moveToX:point.x toY:point.y];

  Tile*otherTile;
  BOOL inside;

  return ![self tile:tile collidesWith:&otherTile inside:&inside skip:tile];
}

- (void) drop:(int)type withColor:(UIColor*)color atPoint:(CGPoint)point redraw:(BOOL)redraw
{
  insist (appDelegate && color);
  insist (type >= 0 && type < NUM_TILES);
    
  [self forgetKilled];

  /*make a new tile*/
  Tile*tile = [[Tile tileOfType:type color:color] retain];
  insist (tile);

  /*convert the point to plane coordinates*/
  point = [self windowPointToPlanePoint:point];
  
  /*move the tile to be centered at the point*/
  [tile moveToX:point.x toY:point.y];
  
  insist (laidTiles);
  
  /*unframe any framed tile*/
  Tile*framedTile = [self getFramedTile];
  if (framedTile)
    [framedTile setFramed:NO];
  
  /*if this is the first tile, make it the center tile*/
  if (![laidTiles count])
  {
    insist (!workingTile);
    [self addToLaidTiles:tile];

    [tile setFramed:YES];
    /*for ease of memory management whenever a tile is laid, it's
      retained only by the laidTiles array*/
    [tile release];
    
    /*make sure it's going to be visible*/
    [self resetVisibleRect:CGPointMake (0, 0)];
    [tile moveToX:-VISIBLE_RECT_SLOP toY:-VISIBLE_RECT_SLOP];
    
    [tile setShowArcs:YES];
  }
  else
  {
    insist (!workingTile);
    workingTile = tile;
    
    /*the working tile is framed*/
    [workingTile setShowArcs:YES];
    [workingTile setFramed:YES];
  }

  if (redraw)
  {
    layerIsDirty = YES;
    [self recomputeVisibleTiles];
    [self setNeedsDisplay];
  }
}


- (void) writeToFile:(NSString*)filename
{
  insist (filename);
  
  /*if the plane is empty then just make sure there's no state file*/
  if ([laidTiles count] == 0 && !workingTile)
  {
    remove ([filename cStringUsingEncoding:NSUTF8StringEncoding]);
    return;
  }
  /*there is something to save*/
  FILE*fp = fopen ([filename cStringUsingEncoding:NSUTF8StringEncoding], "w");
  insist (fp);
  
  /*write the scale*/
  fprintf (fp, "%f\n", [Tile scale]);
  
  /* write the visibleRect*/
  fprintf (fp, "%f %f %f %f\n", visibleRect.origin.x, visibleRect.origin.y, visibleRect.size.width, visibleRect.size.height);
  
  /*the laidTiles count*/
  fprintf (fp, "%d\n", [laidTiles count]);
  
  /*and all the tiles*/
  for (int i = 0; i < [laidTiles count]; i++)
  {
    Tile*tile = [laidTiles objectAtIndex:i];
    [tile writeToFile:fp array:laidTiles];
  }
  
  /*1 if we have a working tile*/
  fprintf (fp, "%d\n", workingTile ? 1 : 0);
  
  /*and finally the workingTile if there is one*/
  if (workingTile)
    [workingTile writeToFile:fp array:laidTiles];
    
  fclose (fp);
}

/*drop a bunch of tiles on the plane*/
#define NUM_TEST_EDGE_TILES 70
#define TEST_TILE_EDGE (PHI * 1.1)

- (void) test
{
  [self reset];
  
  testing = YES;
  
  CGFloat lowY = - (TEST_TILE_EDGE * NUM_TEST_EDGE_TILES / 2.0);
  CGFloat lowX = - (TEST_TILE_EDGE * NUM_TEST_EDGE_TILES / 2.0);
  CGFloat scale = [Tile scale];
  
  UIColor*color = [UIColor blueColor];
  
  for (int i = 0; i < NUM_TEST_EDGE_TILES; i++)
  {
    for (int j = 0; j < NUM_TEST_EDGE_TILES; j++)
    {
      [self drop: j % NUM_TILES withColor:color atPoint:CGPointMake ((lowX + i * TEST_TILE_EDGE) * scale, (lowY + j * TEST_TILE_EDGE) * scale) redraw:NO];
      if (workingTile)
      {
        [self addToLaidTiles:workingTile];
        workingTile = nil;
      }
    }
  }
  layerIsDirty = YES;
  [self recomputeVisibleTiles];
  [self setNeedsDisplay];
  
}


- (BOOL) readFromFile:(NSString*)filename
{
 /*
  [self test];
  return YES;
 */ 
  insist (filename);
  FILE*fp = fopen ([filename cStringUsingEncoding:NSUTF8StringEncoding], "r");
  
  if (!fp) return NO;

  [self reset];
  
  CGFloat scale;
  int r;
  
  /*read the scale*/
  r = fscanf (fp, "%f\n", &scale);
  insist (r == 1 && scale > 0.0);
  if (scale < MIN_SCALE || scale > MAX_SCALE)
    scale = DEFAULT_SCALE;
  
  [Tile setScale:scale];

  /* read the visibleRect*/
  r = fscanf (fp, "%f %f %f %f\n", &visibleRect.origin.x, &visibleRect.origin.y, &visibleRect.size.width, &visibleRect.size.height);
  insist (r == 4 && visibleRect.size.width > 0 && visibleRect.size.height > 0);
  
  int laidTilesCount;
  /*the laidTiles count*/
  r = fscanf (fp, "%d\n", &laidTilesCount);
  insist (r == 1 && laidTiles >= 0);
  BOOL darts = NO;
  
  /*and all the tiles*/
  for (int i = 0; i < laidTilesCount; i++)
  {
    Tile*tile = [[Tile readFromFile:fp] retain];
    insist (tile);
    [tile setShowArcs:YES];
    [self addToLaidTiles:tile];
    if ([tile type] == DART || [tile type] == KITE)
      darts = YES;
  }
    
  /*working tile*/
  int numWorkingTiles;
  r = fscanf (fp, "%d\n", &numWorkingTiles);
  insist (r == 1);
  //NSLog(@"numWorkingTiles is %d numLaid is %d", numWorkingTiles, laidTilesCount);
  
  if (numWorkingTiles)
  {
    workingTile = [[Tile readFromFile:fp] retain];
    [workingTile setShowArcs:YES];
    [workingTile setFramed:YES];
    if ([workingTile type] == DART || [workingTile type] == KITE)
      darts = YES;
  }
  else if (laidTilesCount == 1)
  {
    Tile*tile = [laidTiles objectAtIndex:0];
    insist (tile);
    [tile setFramed:YES];
  }
    
  fclose (fp);
  
  for (int i = 0; i < [laidTiles count]; i++)
  {
    Tile*tile = [laidTiles objectAtIndex:i];
    [tile setNeighborIndexesFromArray:laidTiles];
  }
  
  if (workingTile) [workingTile setNeighborIndexesFromArray:laidTiles];
  
  [appDelegate setDartsAndKites:darts];
  
  layerIsDirty = YES;
  [self recomputeVisibleTiles];
  [self setNeedsDisplay];
  return workingTile != nil || [laidTiles count] != 0;
}


- (CGContextRef) createContextWidth:(int)width height:(int)height
{
  /*create the context*/
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB ();
  insist (colorSpace);
  
  /*prevent huge pictures which crash the phone*/
  int size = (width * height * 4);
  if (size > MAX_PHOTO_BYTES) return 0;
  
  void*bitmapData = malloc (size);
  if (!bitmapData) return 0;
  
  CGContextRef context = CGBitmapContextCreate (bitmapData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast);
  insist (context);
 CGColorSpaceRelease (colorSpace);
  
  /*turn on anti-aliasing*/
  CGContextSetShouldAntialias (context, YES);
  CGContextSetAllowsAntialiasing (context, YES);
  
  return context;
}

-(void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
  if (saveImageRef) 
    CGImageRelease (saveImageRef);
  if (saveContext)
  {
    char*p = CGBitmapContextGetData (saveContext);
    CGContextRelease (saveContext);
    if (p) free (p);  
  }
  if (saveImage)
    [saveImage release];
  saveImageRef = nil;
  saveContext = nil;
  saveImage = nil;
}

/*save to photo album*/
- (BOOL) saveWithLines:(BOOL)withLines
{
  if (![laidTiles count]) return NO;
  
  if (saveImage || saveImageRef || saveContext) return NO;
  
  //CGFloat scale = SAVE_SCALE;
  CGFloat scale = [Tile scale];
  CGRect rect = [self computeBounds];

  int width = rect.size.width * scale;
  int height = rect.size.height * scale;
  if (width <= 0 || height <= 0)
    return NO;
  
  /*get a new context*/
  saveContext = [self createContextWidth:width height:height];
  if (!saveContext) return NO;

  CGContextTranslateCTM (saveContext, -rect.origin.x*scale, -rect.origin.y*scale);
  
  CGContextSetRGBFillColor (saveContext, 1.0, 1.0, 1.0, 1.0);
  CGContextFillRect (saveContext, rect);
  
  [Tile setEnableOrnaments:withLines];

  /*draw all the laid tiles*/
  for (int i = 0; i < [laidTiles count]; i++)
  {
    Tile*tile = [laidTiles objectAtIndex:i];
    insist (tile);
    if (tile == workingTile) continue;
    [tile draw:saveContext scale:scale shadow:NO];
  }
  
  [Tile setEnableOrnaments:YES];
  
  saveImageRef = CGBitmapContextCreateImage (saveContext);
  if (!saveImageRef)
  {
    [self image:nil didFinishSavingWithError:nil contextInfo:nil];
    return NO; 
  }

  saveImage = [[UIImage imageWithCGImage:saveImageRef] retain];
  if (!saveImage)
  {
    [self image:nil didFinishSavingWithError:nil contextInfo:nil];
    return NO;
  }

  [appDelegate playPhotoSound];
  
  UIImageWriteToSavedPhotosAlbum (saveImage, self, @selector (image:didFinishSavingWithError:contextInfo:), nil);

  return YES;
}


- (BOOL)justKilled
{
  return killedTile != nil || coloredTile != nil;
}

- (void) undoKill
{
 
  if (killedTile)
  {
    /*add it back to the laidtiles list*/
    [self addToLaidTiles:killedTile];
    
    /*if there was a neighbor connect it up*/
    if (killedNeighbor)
    {
      [killedNeighbor joinTo:killedNeighbor];
      [self joinAny:killedNeighbor];
      [appDelegate playTockSound];
    }
    else
    {   
      [appDelegate playClickSound];    
    }
  }
  else if (coloredTile)
  {
    insist (coloredTileColor);
    [coloredTile setColor:coloredTileColor];
  }
  
  [self forgetKilled];
  [self recomputeVisibleTiles];
  layerIsDirty = YES;
  [self setNeedsDisplay];  
}


- (void) dealloc
{
  [laidTiles release];
  [visibleTiles release];
  [workingTile release];
  [appDelegate release];
  [sections release];
  if (layerRef)
    CGLayerRelease (layerRef);
  
  for (int i = 0; i < NUM_TILES; i++)
    [helperTiles [i] release];
  [super dealloc];
}


@end
