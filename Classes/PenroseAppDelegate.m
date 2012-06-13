//
//  PenroseAppDelegate.m
//  Penrose
//
//  Created by David Finucane on 12/16/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "PenroseAppDelegate.h"
#import "Tiles.h"
#import "insist.h"
#import "Window.h"
#import "Palette.h"

#define STATE_FILENAME @"state"
#define PALETTES_FILENAME @"palettes"

#define NUM_PRESETS 8
static char*thePresetNames [NUM_PRESETS] =
{
"Star",
"Sun",
"Ace",
"Deuce",
"Jack",
"Queen",
"King",
"Batman"
};

/*ripped off from glpaint*/
#define kAccelerometerFrequency			25 //Hz
#define kFilteringFactor				0.1
#define kMinEraseInterval				0.5
#define kEraseAccelerationThreshold		(2.0 * 1.2)
UIAccelerationValue	myAccelerometer[3];
CFTimeInterval lastTime;

#define TILE_BUTTON_SCALE 14

@implementation PenroseAppDelegate

NSString*kPaletteIndexKey=@"paletteIndexKey";
NSString*kMutedKey=@"mutedKey";
NSString*kPresetIndexKey=@"presetIndex";

/*these 2 things along with the buttons and colors arrays do
 what we normally would have used a mapTable for. just maps
 colors to buttons.*/

-(UIColor*) colorForButton:(UIButton*)button
{
  for (int i = 0; i < NUM_BUTTONS; i++)
  {
    if (buttons [i] == button)
      return colors [i];
  }
  insist (0);
  return nil;
}

-(int) indexOfButton:(UIButton*)button
{
  for (int i = 0; i < NUM_BUTTONS; i++)
  {
    if (buttons [i] == button)
      return i;
  }
  insist (0);
  return 0;
}

-(void) setColor:(UIColor*)color forButton:(UIButton*)button
{
  insist (button && color);
  
  for (int i = 0; i < NUM_BUTTONS; i++)
  {
    if (buttons [i] == button)
    {
      [color retain];
      if (colors [i])
        [colors [i] release];
      colors [i] = color;
      return;
    }
  }
  insist (0);
}

- (void) registerDefaults
{
  NSMutableDictionary*defaults = [NSMutableDictionary dictionary];
  insist (defaults);
  
  [defaults setObject:[NSNumber numberWithInt:0] forKey:kPaletteIndexKey];
  [defaults setObject:[NSNumber numberWithInt:0] forKey:kPresetIndexKey];
  [defaults setObject:[NSNumber numberWithBool:NO] forKey:kMutedKey];
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (void) dumpState
{  
  insist (palettes);
  
  /*save defaults*/
  [[NSUserDefaults standardUserDefaults] setInteger:currentPaletteIndex forKey:kPaletteIndexKey];
  [[NSUserDefaults standardUserDefaults] setInteger:currentPresetIndex forKey:kPresetIndexKey];

  [[NSUserDefaults standardUserDefaults] setBool:muted forKey:kMutedKey];

  /*save plane state*/
  NSArray*array = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
  insist (array);
  NSString*dir = [array objectAtIndex:0];
  NSString*path = [NSString stringWithFormat:@"%@/%@", dir, STATE_FILENAME];
  insist (path);
  
  [plane writeToFile:path];
  
  /*save palettes*/
  path = [NSString stringWithFormat:@"%@/%@", dir, PALETTES_FILENAME];
  insist (path);
  FILE*fp = fopen ([path cStringUsingEncoding:NSUTF8StringEncoding], "w");
  insist (fp);
  
  fprintf (fp, "%d\n", [palettes count]);
  for (int i = 0; i < [palettes count]; i++)
  {
    Palette*palette = [palettes objectAtIndex:i];
    insist (palette);
    [palette write:fp];
  }
  fclose (fp);
}

- (BOOL) restoreState
{
  currentPresetIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kPresetIndexKey];
  
  if (currentPresetIndex < 0 || currentPresetIndex > NUM_PRESETS)
    currentPresetIndex = 0;
  
  /*get the document directory for our app so we know where to find our data files*/

  NSArray*array = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
  insist (array);
  NSString*dir = [array objectAtIndex:0];
  NSString*path = [NSString stringWithFormat:@"%@/%@", dir, STATE_FILENAME];
  insist (path); 
  
  @try
  {
    return [plane readFromFile:path];
  }
  @catch (NSException*e)
  {
    NSLog ([NSString stringWithFormat:@"%@%@", [e name], [e reason]]);
    return NO;
  }
  return NO;
}

/*we are being shut down. save state*/
- (void)applicationWillTerminate:(UIApplication *)application
{
  [self dumpState];
}


- (void) setButtonColor:(UIColor*)color button:(UIButton*)button 
{  
  insist (color);
  
  /*remember the new color for this button*/
  [self setColor:color forButton:button];
  
  /*change the button images*/
  UIImage*image = [imageMaker squareImage:color selected:NO];
  insist (image);  
  [button setImage:image forState:UIControlStateNormal];
  
  image = [imageMaker squareImage:color selected:YES];
  insist (image);  
  [button setImage:image forState:UIControlStateSelected];
}

- (void) setTileButtonColor:(UIColor*)color button:(UIButton*)button
{
  insist (color);
  
  /*get button type*/
  int type;
  if (button == firstTileButton)
    type = dartsAndKites ? DART : THIN;
  else
    type = dartsAndKites ? KITE : THICK;
  
  /*remember the new color for this button*/
  [self setColor:color forButton:button];
  
  /*make the new images and load them into the button*/
  UIImage*image = [imageMaker tileImageOfType:type color:color scale:TILE_BUTTON_SCALE selected:NO autoSize:NO shadow:NO framed:NO];
  insist (image);  
  [button setImage:image forState:UIControlStateNormal];
  image = [imageMaker tileImageOfType:type color:color scale:TILE_BUTTON_SCALE selected:YES autoSize:NO shadow:NO framed:NO];
  insist (image);  
  [button setImage:image forState:UIControlStateSelected];
}

- (UIView*)tileViewForButton:(UIButton*)button
{
  int type;  
  if (button == firstTileButton)
    type = dartsAndKites ? DART : THIN;
  else
    type = dartsAndKites ? KITE : THICK;

  /*get the current color*/
  UIColor*color = [self colorForButton:button];
  insist (color);
  
  /*make the image at the current tile scale*/
  UIImage*image = [imageMaker tileImageOfType:type color:color scale:[Tile scale] selected:NO autoSize:YES shadow:YES framed:YES];
  
  /*return a new image view*/
  UIImageView*view = [[[UIImageView alloc] initWithImage:image] autorelease];
  insist (view);
  [view setOpaque:NO];
  return view;
}

- (Palette*) currentPalette
{
  insist (palettes);
  insist (currentPaletteIndex >= 0 && currentPaletteIndex < [palettes count]);
  return [palettes objectAtIndex:currentPaletteIndex];
}

- (void) updatePaletteLabel
{
  insist (paletteLabel);
  [paletteLabel setText:[NSString stringWithFormat:@"%d", currentPaletteIndex]];
}

- (void) setButtonColorsFromPalette:(Palette*)palette
{
  insist (palette);
  int i;
  for (i = 0; i < 3; i++)
    [self setButtonColor:[palette colorAtIndex:i] button:buttons[i]];
  for (; i < NUM_BUTTONS; i++)
    [self setTileButtonColor:[palette colorAtIndex:i] button:buttons [i]];
}

- (void) setDartsAndKites:(BOOL)theDartsAndKites
{
  dartsAndKites = theDartsAndKites;
  [self setButtonColorsFromPalette:[self currentPalette]];
}

- (void) resetWithDartsAndKites:(BOOL)theDartsAndKites
{
  insist (plane);
  [plane reset];
  dartsAndKites = theDartsAndKites;
  [self setButtonColorsFromPalette:[self currentPalette]];
}

- (void) loadPalettes
{
  insist (palettes);
  insist (paletteSlider);
  insist (paletteLabel);
  
  [palettes removeAllObjects];
  
  @try
  { 
    /*first try to open the user's modified palettes*/
    NSArray*array = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    insist (array);
    NSString*dir = [array objectAtIndex:0];
    NSString*path = [NSString stringWithFormat:@"%@/%@", dir, PALETTES_FILENAME];
    insist (path);
    FILE*fp = fopen ([path cStringUsingEncoding:NSUTF8StringEncoding], "r");
  
    if (!fp)
    {
      /*there aren't any. get the defaults*/
      path = [[NSBundle mainBundle] pathForResource:PALETTES_FILENAME ofType:@""];
      insist (path); 
  
      fp = fopen ([path cStringUsingEncoding:NSUTF8StringEncoding], "r");
    }
    insist (fp);
    int numPalettes = 0;
    int r = fscanf (fp, "%d", &numPalettes);
    insist (r == 1 && numPalettes > 0);

    for (int i = 0; i < numPalettes; i++)
      [palettes addObject:[[Palette alloc] initFromFile:fp]];
    fclose (fp);
  }
  @catch (NSException*e)
  {
    NSLog ([NSString stringWithFormat:@"%@%@", [e name], [e reason]]);
    
    /*something bad happened from the files. make a default pallet set*/
    [palettes removeAllObjects];
    [palettes addObject:[[[Palette alloc] init] autorelease]];
  }
  insist ([palettes count]);
  
  currentPaletteIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kPaletteIndexKey];

  if (currentPaletteIndex < 0 || currentPaletteIndex > [palettes count])
    currentPaletteIndex = 0;
  [self updatePaletteLabel];
  
  [paletteSlider setMinimumValue:0];
  [paletteSlider setMaximumValue:[palettes count] - 1];
  [paletteSlider setValue:currentPaletteIndex];
}

- (void) bringUpStartScreen
{
  /*make startView*/
  startViewController = [[StartViewController alloc] initWithNibName:@"StartView" bundle:nil appDelegate:self];
  [window addSubview:[startViewController view]];
  started = NO;
  alertViewUp = NO;
}

- (void) applicationDidFinishLaunching:(UIApplication *)application
{ 
  insist (window && toolbar);
  [self registerDefaults];
    
  [((Window*)window) setAppDelegate:self];
  
  [application setStatusBarHidden:YES animated:NO];

  /*slide the colorView away*/
  insist (colorView);
  [colorView setCenter: CGPointMake (-[colorView center].x, [colorView center].y)];
  
  /*make the imageMaker*/
  imageMaker = [[ImageMaker alloc]init];
  insist (imageMaker);
  
  palettes = [[NSMutableArray alloc] init];
  insist (palettes);
  [self loadPalettes];
  
  /*set up button actions in code so we can detect double click*/
  insist (firstColorButton && secondColorButton && firstTileButton && secondTileButton);
  insist (thirdColorButton && deleteButton);
  
  /*kludge because iPhone OS doesn't have NSMapTable*/
  buttons [0] = firstColorButton;
  buttons [1] = secondColorButton;
  buttons [2] = thirdColorButton;
  buttons [3] = firstTileButton;
  buttons [4] = secondTileButton;
  
  [firstColorButton addTarget:self action:@selector(colorAction:forEvent:) forControlEvents:UIControlEventTouchDown];
  [secondColorButton addTarget:self action:@selector(colorAction:forEvent:) forControlEvents:UIControlEventTouchDown];
  [thirdColorButton addTarget:self action:@selector(colorAction:forEvent:) forControlEvents:UIControlEventTouchDown];
  
  [firstTileButton addTarget:self action:@selector(tileAction:forEvent:) forControlEvents:UIControlEventTouchDown];
  [secondTileButton addTarget:self action:@selector(tileAction:forEvent:) forControlEvents:UIControlEventTouchDown];

  /*now that we have the palettes loaded we can set up the initial colors*/
  [self setButtonColorsFromPalette:[self currentPalette]];
  
  /*set up the delete button*/
  UIImage*image = [imageMaker xImageSelected:NO];
  insist (image);  
  [deleteButton setImage:image forState:UIControlStateNormal];
  
  image = [imageMaker xImageSelected:YES];
  insist (image);  
  [deleteButton setImage:image forState:UIControlStateSelected];
  
  CGRect r = [[UIScreen mainScreen] bounds];
  r.size.height -= [toolbar frame].size.height;
  
  selectedButton = nil;

  /*make new plane and throw it into the window but underneath the colorView.*/
  plane = [[Plane alloc] initWithFrame: CGRectMake(0, 0, r.size.width, r.size.height) appDelegate:self];
  [Tile setScale:DEFAULT_SCALE];  
  
  /*load the tap sound*/
  CFBundleRef mainBundle = CFBundleGetMainBundle ();
  CFURLRef urlRef = CFBundleCopyResourceURL(mainBundle, CFSTR ("tap"), CFSTR ("aif"), NULL);
  AudioServicesCreateSystemSoundID (urlRef, &clickSound);
  CFRelease (urlRef);
  
  urlRef = CFBundleCopyResourceURL(mainBundle, CFSTR ("tick"), CFSTR ("wav"), NULL);
  AudioServicesCreateSystemSoundID (urlRef, &tickSound);
  CFRelease (urlRef);
  
  urlRef = CFBundleCopyResourceURL(mainBundle, CFSTR ("tock"), CFSTR ("wav"), NULL);
  AudioServicesCreateSystemSoundID (urlRef, &tockSound);
  CFRelease (urlRef);
  
  urlRef = CFBundleCopyResourceURL(mainBundle, CFSTR ("negative"), CFSTR ("wav"), NULL);
  AudioServicesCreateSystemSoundID (urlRef, &negativeSound);
  CFRelease (urlRef);
  
  urlRef = CFBundleCopyResourceURL(mainBundle, CFSTR ("select"), CFSTR ("caf"), NULL);
  AudioServicesCreateSystemSoundID (urlRef, &selectSound);
  CFRelease (urlRef);
  
  urlRef = CFBundleCopyResourceURL(mainBundle, CFSTR ("erase"), CFSTR ("caf"), NULL);
  AudioServicesCreateSystemSoundID (urlRef, &eraseSound);
  CFRelease (urlRef);
  
  urlRef = CFBundleCopyResourceURL(mainBundle, CFSTR ("photo"), CFSTR ("wav"), NULL);
  AudioServicesCreateSystemSoundID (urlRef, &photoSound);
  CFRelease (urlRef);
  
  presetLabel = nil;
  
  [window addSubview:plane];
  [window sendSubviewToBack:plane];
  
  /*try to set up the plane from a saved file*/
  if ([self restoreState])
  {
    started = YES;
  }
  else
  {
    /*no saved state so bring up the startView*/
    [self bringUpStartScreen];
  }
  
  /*this is ripped off from glpaint*/
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kAccelerometerFrequency)];
	[[UIAccelerometer sharedAccelerometer] setDelegate:self];
  
  muted = [[NSUserDefaults standardUserDefaults] boolForKey:kMutedKey];

  [window makeKeyAndVisible];
}

- (BOOL) started
{
  return started;
}


- (void) startWithDartsAndKites:(BOOL)theDartsAndKites
{
  insist (startViewController);
  [[startViewController view] removeFromSuperview];
  [startViewController release];
  [self resetWithDartsAndKites: theDartsAndKites];
  
  started = YES;
}

- (void) removePresetLabel
{
  insist (presetLabel);
  
  [presetLabel removeFromSuperview];
  [presetLabel release];
  presetLabel = nil;
}

- (void) startWithPreset
{
  insist (currentPresetIndex >= 0 && currentPresetIndex < NUM_PRESETS);
  
   @try
  {
    
    NSString*path = [[NSBundle mainBundle] pathForResource:
                     [NSString stringWithFormat:@"%s", thePresetNames [currentPresetIndex]]
                                                    ofType:@""];
    insist (path); 
    
    
    [[startViewController view] removeFromSuperview];
    [startViewController release];
    [self resetWithDartsAndKites:YES];
    started = YES;
    
    BOOL b = [plane readFromFile:path];
    insist (b);
    
    if (!presetLabel)
    {
      CGRect r = [[UIScreen mainScreen] bounds];

      r.origin.y = r.size.height - 150;
      r.size.height = 50;
      presetLabel = [[UILabel alloc] initWithFrame:r];
      insist (presetLabel);
    }
    
    [presetLabel setFont:[UIFont systemFontOfSize:21]];
    
    [presetLabel setText:[NSString stringWithFormat:@"%s", thePresetNames [currentPresetIndex]]];
    [presetLabel setTextAlignment:UITextAlignmentCenter];

    [window addSubview:presetLabel];
    [window bringSubviewToFront:presetLabel];
    
    [UIView beginAnimations:@"dc" context:nil];
    [UIView setAnimationDuration:3.0];
    [presetLabel setAlpha:0];
    [UIView commitAnimations];
        
    [self performSelector:@selector(removePresetLabel) withObject:self afterDelay:5.0];

    currentPresetIndex = (currentPresetIndex + 1)  % NUM_PRESETS;
  }
  @catch (NSException*e)
  {
    NSLog ([NSString stringWithFormat:@"%@%@", [e name], [e reason]]);
    
    /*something bad happened. just start w/ kites and darts*/
    return;
  }
}

- (void) playClickSound
{
  if (!muted)
    AudioServicesPlaySystemSound (clickSound);
}

- (void) playTickSound
{  
  if (!muted)
    AudioServicesPlaySystemSound (tickSound);
}

- (void) playTockSound
{
  if (!muted)
    AudioServicesPlaySystemSound (tockSound);
}

- (void) playNegativeSound
{
  if (!muted)
    AudioServicesPlaySystemSound (negativeSound);
}

- (void) playSelectSound
{
  if (!muted)
    AudioServicesPlaySystemSound (selectSound);
}

- (void) playEraseSound
{
  if (!muted)
    AudioServicesPlaySystemSound (eraseSound);
}

- (void) playPhotoSound
{
  if (!muted)
    AudioServicesPlaySystemSound (photoSound);
}


- (UIColor*)getSliderColor
{
  insist (redSlider && blueSlider && greenSlider);
  float r,g,b;
  r = [redSlider value] / 255.0;
  g = [greenSlider value] / 255.0;
  b = [blueSlider value] / 255.0;

  return [UIColor colorWithRed:r green:g blue:b alpha:1.0];
}

- (UIColor*)getSelectedColor
{
  insist (selectedButton);
  return [self colorForButton: selectedButton];
}


- (void) setSwatchColor:(UIColor*)color
{
  insist (swatchView && hexLabel);
  
  CGColorRef ref = [color CGColor];
  insist (CGColorGetNumberOfComponents (ref) == 4);
  const CGFloat*components = CGColorGetComponents (ref);
  
  int r = components [0] * 255;
  int g = components [1] * 255;
  int b = components [2] * 255;
  
  [swatchView setBackgroundColor:color];
  [hexLabel setText:[NSString stringWithFormat:@"#%2.2X%2.2X%2.2X", r, g, b]];
}

- (void) updateColorLabelForSlder:(UISlider*)slider
{
  insist (slider);
  int value = (int) [slider value];
  insist (value >= 0 && value < 256);
  
  UILabel*label;
  if (slider == redSlider)
    label = redLabel;
  else label = (slider == greenSlider) ? greenLabel : blueLabel;
  [label setText:[NSString stringWithFormat:@"%d", value]];  
}


- (void) setSliderColor:(UIColor*)color
{
  insist (color);
  insist (redSlider && blueSlider && greenSlider);
  
  CGColorRef ref = [color CGColor];
  insist (CGColorGetNumberOfComponents (ref) == 4);
  const CGFloat*components = CGColorGetComponents (ref);
  
  [self setSwatchColor:color];
  
  [redSlider setValue: components [0] * 255];
  [greenSlider setValue: components [1] * 255];
  [blueSlider setValue: components [2] * 255];
  [self updateColorLabelForSlder:redSlider];
  [self updateColorLabelForSlder:greenSlider];
  [self updateColorLabelForSlder:blueSlider];
}

- (IBAction) paletteSliderChanged:(id)sender
{
  insist (sender && sender == paletteSlider);
  insist (palettes);
  
  int index = (int) [paletteSlider value];
  insist (index >= 0 && index < [palettes count]);
  currentPaletteIndex = index;
  
  [self setButtonColorsFromPalette:[self currentPalette]];
  [self updatePaletteLabel];
  if (selectedButton)
    [self setSliderColor:[self getSelectedColor]];
}


- (BOOL) colorViewVisible
{
  return [colorView center].x > 0;
}

- (UIButton*)firstTileButton
{
  return firstTileButton;
}

- (UIButton*)secondTileButton
{
  return secondTileButton;
}

- (void) deselect
{
  if (selectedButton)
  {
    [selectedButton setSelected:NO];
    selectedButton = nil;
  }
}

- (void) toggleColorView
{
  if (![self colorViewVisible])
  {
    insist (selectedButton);
    [self setSliderColor:[self getSelectedColor]];
  }
  
  [UIView beginAnimations:@"dc" context:nil];
  [UIView setAnimationDuration:0.5];
  [colorView setCenter: CGPointMake (-[colorView center].x, [colorView center].y)];
  [UIView commitAnimations];
}

- (void) selectButton:(id)button
{
  insist (button);
  
  if (selectedButton && selectedButton != button)
    [selectedButton setSelected:NO];
  [button setSelected:YES];
  selectedButton = button;
  
  if ([self colorViewVisible])
  {
    insist (selectedButton);
    [self setSliderColor:[self getSelectedColor]];
  }
}

- (void) swapSelectedColorWithTileType:(int)type
{
  /*get button*/
  UIButton*button = (type == DART || type == THIN) ? firstTileButton : secondTileButton;

  insist (selectedButton && selectedButton != button);
  
  /*get the 2 colors to swap*/
  UIColor*selectedColor = [self getSelectedColor];
  UIColor*tileColor = [self colorForButton:button];
  
  /*swap them*/
  [self setButtonColor:tileColor button:selectedButton];
  [self setTileButtonColor:selectedColor button:button];
  
  /*update the palette ordering too*/
  Palette*palette = [self currentPalette];
  insist (palette);
  [palette setColor:tileColor atIndex:[self indexOfButton:selectedButton]];
  [palette setColor:selectedColor atIndex:[self indexOfButton:button]];
}

-(void)deleteAction:(id)sender
{
  if ([self colorViewVisible])
    return;
  
  /*unselect anyone else*/
  if (selectedButton && selectedButton != sender)
  {
    [selectedButton setSelected:NO];
    selectedButton = nil;
  }
  
  /*toggle*/
  [self playSelectSound];
  if ([sender state] == UIControlStateSelected)
  {
    [sender setSelected:NO];
    [plane setUserState:CURSOR];
    selectedButton = nil;
  }
  else
  {
    [sender setSelected:YES];
    [plane setUserState:DELETE];
    selectedButton = sender;
  }
}

-(void)colorAction:(id)sender forEvent:(UIEvent*)event
{
  NSSet*touches = [event allTouches];
  UITouch*touch = [touches anyObject];
  
  /*if the color view isn't up clicking on an already clicked button unselects it*/
  if ([touch tapCount] == 1 && ![self colorViewVisible] && selectedButton == sender)
  {
    [self playSelectSound];
    [plane setUserState:CURSOR];
    [sender setSelected:NO];
    selectedButton = nil;
  }
  else
  {
    if (selectedButton != sender)
      [self playSelectSound];
    [self selectButton:sender];
    [plane setUserState:PAINT];
  }
  
  if ([touch tapCount] > 1 && ![self colorViewVisible])
    [self toggleColorView];
}


-(void)tileAction:(id)sender forEvent:(UIEvent*)event
{
//  NSSet*touches = [event allTouches];
//  UITouch*touch = [touches anyObject];

  /*no matter what, clicking on a tile unselects the current selected button*/
  if (selectedButton)
  {
    [selectedButton setSelected:NO];
    selectedButton = nil;
  }
  [plane setUserState:CURSOR];
  
  if ([self colorViewVisible])
  {
    /*only select a tile if the color view is up*/
    [self selectButton:sender];
    [self playSelectSound];
  }
 }

/*called when the user shakes the cam*/
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (alertView == trashAlertView)
  {
    alertViewUp = NO;
    insist (buttonIndex >=0 && buttonIndex < 6);
    
    switch (buttonIndex)
    {
      case 0:
        break;
      case 1:
        /*the user said yes. delete the picture*/
        [self resetWithDartsAndKites:dartsAndKites];
        
        /*and appease apple*/
        [self bringUpStartScreen];
        break;
      case 2:
        /*save the picture to the photo album*/
        if (![plane saveWithLines:YES])
          [self playNegativeSound];
        
        break;
      case 3:
        /*save the picture to the album*/
        if (![plane saveWithLines:NO])
          [self playNegativeSound];
        break;
      case 4:
        /*toggle sound*/
        muted = !muted;
        break;
      case 5:
        /*undo*/
        if ([plane justKilled])
          [plane undoKill];
        break;
      default:
        insist (0);
    }
  }
}

- (void)shake
{
  /*don't put up an alert if we already have one up*/
  
  if (alertViewUp || !started) return;
  alertViewUp = YES;

  /*make an alert view asking delete, photo, or cancel*/
  trashAlertView = [[UIAlertView alloc]initWithTitle:@""
                                              message:@""
                                             delegate:self
                                    cancelButtonTitle:@"Cancel"
                                    otherButtonTitles:@"Start Over",
                    nil];

  [trashAlertView addButtonWithTitle:@"Add to Photo Album"];
  [trashAlertView addButtonWithTitle:@"Photo Without Lines"];
  [trashAlertView addButtonWithTitle:muted ? @"Sound On" : @"Sound Off"];
  
  if (1 && [plane justKilled])
    [trashAlertView addButtonWithTitle:@"Undo"];
  
  insist (trashAlertView);
  
  /*ask the question. apparently "show" doesn't block here and someone is retaining the alert*/
  [trashAlertView show];
  [trashAlertView release];
}


- (void)save:(id)sender
{
  NSLog(@"save");
}

- (IBAction) colorSliderChanged:(id)sender
{
  insist (sender);
  [self updateColorLabelForSlder:sender];
  
  UIColor*color = [self getSliderColor];
  insist (color);
  [self setSwatchColor:color];
  
  /*now update the color of the selected button*/
  insist (selectedButton);
  if (selectedButton == firstTileButton || selectedButton == secondTileButton)
    [self setTileButtonColor:color button:selectedButton];
  else
    [self setButtonColor:color button:selectedButton];
  
  Palette*palette = [self currentPalette];
  insist (palette);
  [palette setColor:color atIndex: [self indexOfButton:selectedButton]];
}

/*called when the user clicks done on the color view*/
- (IBAction) colorDone:(id)sender
{
  insist ([self colorViewVisible]);

  /*make sure there are no selected buttons*/
  if (selectedButton)
  {
    [selectedButton setSelected:NO];
    selectedButton = nil;
  }
  [plane setUserState:CURSOR];
  
  /*hide the view*/
  [self toggleColorView];
  
  /*check for the test pattern. it's the 3 buttons set to rgb 5/23/1971*/
  int i;
  for (i = 0; i < 1; i++)
  {
    unsigned c = [Tile numberFromColor: colors [i]];
    if (c != 71 + (23 << 8) + (5 << 16))
      break;

  }
  if (i == 1)
  {
    /*set the colors back to the defaults so we don't infinite loop*/
    [self setButtonColorsFromPalette: [[[Palette alloc] init] autorelease]];
    /*run the test*/
    [plane test];
  }
}

/*return yes if a tile can be dropped onto the plane without landing on another tile*/
- (BOOL) canDrop:(UIButton*)button atScreenPoint:(CGPoint)point
{
  insist (plane);
  
  /*get button type*/
  int type;
  if (button == firstTileButton)
    type = dartsAndKites ? DART : THIN;
  else
    type = dartsAndKites ? KITE : THICK;

  /*since the plane is on the top of the window the coordinate system is the same*/
  return [plane canDrop:type atPoint:point];
}

- (void) drop:(UIButton*)button atScreenPoint:(CGPoint)point
{
  insist (plane);
  
  /*get button type and color*/
  int type;
  UIColor*color;
  if (button == firstTileButton)
  {
    type = dartsAndKites ? DART : THIN;
    color = [self colorForButton:firstTileButton];
  }
  else
  {
    type = dartsAndKites ? KITE : THICK;
    color = [self colorForButton:secondTileButton];
  }
  
  /*since the plane is on the top of the window the coordinate system is the same*/
  [plane drop:type withColor:color atPoint:point redraw:YES];
}


/*ripped off from glpaint*/
- (void) accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{
	UIAccelerationValue				length,
  x,
  y,
  z;
	
	//Use a basic high-pass filter to remove the influence of the gravity
	myAccelerometer[0] = acceleration.x * kFilteringFactor + myAccelerometer[0] * (1.0 - kFilteringFactor);
	myAccelerometer[1] = acceleration.y * kFilteringFactor + myAccelerometer[1] * (1.0 - kFilteringFactor);
	myAccelerometer[2] = acceleration.z * kFilteringFactor + myAccelerometer[2] * (1.0 - kFilteringFactor);
	// Compute values for the three axes of the acceleromater
	x = acceleration.x - myAccelerometer[0];
	y = acceleration.y - myAccelerometer[1];
	z = acceleration.z - myAccelerometer[2];
	
	//Compute the intensity of the current acceleration 
	length = sqrt(x * x + y * y + z * z);
	// If above a given threshold, play the erase sounds and erase the drawing view
	if((length >= kEraseAccelerationThreshold) && (CFAbsoluteTimeGetCurrent() > lastTime + kMinEraseInterval))
  {
    [self shake];
	}
} 

- (void) dealloc
{
  AudioServicesDisposeSystemSoundID (clickSound);
  AudioServicesDisposeSystemSoundID (tickSound);
  AudioServicesDisposeSystemSoundID (tockSound);
  AudioServicesDisposeSystemSoundID (negativeSound);
  AudioServicesDisposeSystemSoundID (eraseSound);
  AudioServicesDisposeSystemSoundID (selectSound);
  AudioServicesDisposeSystemSoundID (photoSound);
  [presetLabel release];
  [plane release];
  [palettes release];
  [imageMaker release];
  for (int i = 0; i < NUM_BUTTONS; i++)
    [colors [i] release];
  [super dealloc];
}


@end
