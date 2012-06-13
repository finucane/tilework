//
//  PenroseAppDelegate.h
//  Penrose
//
//  Created by David Finucane on 12/16/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Plane.h"
#import "ImageMaker.h"
#import "StartViewController.h"

#include <AudioToolbox/AudioToolbox.h>

#define NUM_BUTTONS 5
#define DEFAULT_SCALE 30

@interface PenroseAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate, UIAccelerometerDelegate>
{
  IBOutlet UIWindow*window;
  IBOutlet UIView*toolbar;
  IBOutlet UIButton*firstColorButton;
  IBOutlet UIButton*secondColorButton;
  IBOutlet UIButton*thirdColorButton;
  IBOutlet UIButton*deleteButton;
  IBOutlet UIButton*firstTileButton;
  IBOutlet UIButton*secondTileButton;
  IBOutlet UIView*colorView;
  IBOutlet UIView*swatchView;
  IBOutlet UILabel*hexLabel;
  IBOutlet UISlider*redSlider;
  IBOutlet UISlider*greenSlider;
  IBOutlet UISlider*blueSlider;
  IBOutlet UILabel*redLabel;
  IBOutlet UILabel*greenLabel;
  IBOutlet UILabel*blueLabel;
  IBOutlet UISlider*paletteSlider;
  IBOutlet UILabel*paletteLabel;
  UIButton*selectedButton;
  UIAlertView*trashAlertView;
  Plane*plane;
  ImageMaker*imageMaker;
  BOOL dartsAndKites;
  SystemSoundID clickSound, tickSound, tockSound, negativeSound;
  SystemSoundID eraseSound, selectSound, photoSound;
  UIButton*buttons [NUM_BUTTONS];
  UIColor*colors [NUM_BUTTONS];
  UIViewController*startViewController;
  BOOL started;
  BOOL alertViewUp;
  BOOL muted;
  NSMutableArray*palettes;
  int currentPaletteIndex;
  int currentPresetIndex;
  UILabel*presetLabel;
}

- (IBAction) save:(id)sender;
- (IBAction) colorSliderChanged:(id)sender;
- (IBAction) paletteSliderChanged:(id)sender;
- (IBAction) colorDone:(id)sender;
- (IBAction) deleteAction:(id)sender;

- (UIButton*)firstTileButton;
- (UIButton*)secondTileButton;
- (UIView*)tileViewForButton:(UIButton*)button;
- (UIColor*)getSelectedColor;
- (BOOL) colorViewVisible;
- (void) tileAction:(id)sender forEvent:(UIEvent*)event;
- (BOOL) canDrop:(UIButton*)button atScreenPoint:(CGPoint)point;
- (void) drop:(UIButton*)button atScreenPoint:(CGPoint)point;
- (void) playClickSound;
- (void) playTickSound;
- (void) playTockSound;
- (void) playNegativeSound;
- (void) playEraseSound;
- (void) playSelectSound;
- (void) playPhotoSound;
- (void) startWithDartsAndKites:(BOOL)theDartsAndKites;
- (void) startWithPreset;
- (BOOL) started;
- (void) setDartsAndKites:(BOOL)theDartsAndKites;
- (void) swapSelectedColorWithTileType:(int)type;
- (void) deselect;
@end

