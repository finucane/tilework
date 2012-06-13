//
//  Palette.h
//  Penrose
//
//  Created by finucane on 1/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define NUM_PALETTE_COLORS 5

@interface Palette : NSObject
{
  UIColor*colors [NUM_PALETTE_COLORS];
}

- (id) init;
- (id) initFromFile:(FILE*)fp;
- (UIColor*) colorAtIndex:(int)index;
- (void) setColor:(UIColor*)color atIndex:(int)index;
- (void) write:(FILE*)fp;
@end
