//
//  ImageMaker.h
//  Penrose
//
//  Created by finucane on 12/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tiles.h"

@interface ImageMaker : NSObject
{
  Kite*kite;
  Dart*dart;
  Thick*thick;
  Thin*thin;
}

- (UIImage*)tileImageOfType:(int)type color:(UIColor*)color scale:(CGFloat) scale selected:(BOOL)selected autoSize:(BOOL)autoSize shadow:(BOOL)shadow framed:(BOOL)framed;
- (UIImage*)squareImage:(UIColor*)color selected:(BOOL)selected;
- (UIImage*)xImageSelected:(BOOL)selected;
@end
