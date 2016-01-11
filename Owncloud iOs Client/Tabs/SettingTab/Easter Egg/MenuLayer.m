//
//  WinLayer.m
//  SpaceInvaders
//
//  Created by Tyler Biethman on 5/27/12.
//  Copyright 2012 Cerner Corporation. All rights reserved.
//

#import "MenuLayer.h"
#import "HelloWorldLayer.h"

@implementation MenuLayer

NSString *const menuTypeWelcome = @"WELCOME";
NSString *const menuTypeWin = @"WIN";
NSString *const menuTypeLose = @"LOSE";

// Helper class method that creates a Scene with the WinLayer as the only child.
// Here is the scene it is automatially created by the template
+ (CCScene *)sceneWithMenuType:(NSString *)type
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an GameOverLayer object.
	MenuLayer *layer = [MenuLayer node];
	
    if ([type isEqualToString:menuTypeWin])
    {
        [layer createWinMenu];
    }
    else if ([type isEqualToString:menuTypeLose])
    {
        [layer createLoseMenu];
    }
    else
    {
        [layer createIntroductionMenu];
    }

	// add layer as a child to scene
	[scene addChild:layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
- (id)init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if ((self=[super init]))
    {        
        self.isTouchEnabled = YES;
        [[CCDirector sharedDirector] setDisplayStats:NO];
	}
    
	return self;
}

- (void)createIntroductionMenu
{
    
    // Create some menu items
    CCMenuItemImage * logo = [CCMenuItemImage itemWithNormalImage:@"CompanyLogo.png"
                                                         selectedImage:@"CompanyLogo.png"
                                                                target:nil
                                                              selector:nil];
    CCLabelTTF *lbl1= [CCLabelTTF labelWithString:NSLocalizedString(@"new_game", nil) fontName:@"verdana" fontSize:25];
    CCMenuItemLabel *menuItem1 = [CCMenuItemLabel itemWithLabel:lbl1 target:self selector:@selector(startGame)];

    CCLabelTTF *lbl2= [CCLabelTTF labelWithString:NSLocalizedString(@"quit_game", nil) fontName:@"verdana" fontSize:20];
    CCMenuItemLabel *menuItem2 = [CCMenuItemLabel itemWithLabel:lbl2 target:self selector:@selector(endGame)];
    
    
    // Create a menu and add your menu items to it
    CCMenu * myMenu = [CCMenu menuWithItems:logo,menuItem1,menuItem2,nil];
    
    // Arrange the menu items vertically
    [myMenu alignItemsVertically];
    
    // add the menu to your scene
    [self addChild:myMenu];
}

- (void)createWinMenu
{    
    // Create some menu items
    CCMenuItemImage * logo = [CCMenuItemImage itemWithNormalImage:@"CompanyLogo.png"
                                                    selectedImage:@"CompanyLogo.png"
                                                           target:nil
                                                         selector:nil];
    
    CCLabelTTF *lbl1= [CCLabelTTF labelWithString:NSLocalizedString(@"retry_game", nil) fontName:@"verdana" fontSize:25];
    CCMenuItemLabel *menuItem1 = [CCMenuItemLabel itemWithLabel:lbl1 target:self selector:@selector(retry)];
    
    CCLabelTTF *lbl2= [CCLabelTTF labelWithString:NSLocalizedString(@"quit_game", nil) fontName:@"verdana" fontSize:20];
    CCMenuItemLabel *menuItem2 = [CCMenuItemLabel itemWithLabel:lbl2 target:self selector:@selector(endGame)];
    
    // Create a menu and add your menu items to it
    CCMenu * myMenu = [CCMenu menuWithItems:logo,menuItem1,menuItem2,nil];
    
    // Arrange the menu items vertically
    [myMenu alignItemsVertically];
    
    // add the menu to your scene
    [self addChild:myMenu];
}

- (void)createLoseMenu
{    
    // Create some menu items
    CCMenuItemImage * logo = [CCMenuItemImage itemWithNormalImage:@"CompanyLogo.png"
                                                    selectedImage:@"CompanyLogo.png"
                                                           target:nil
                                                         selector:nil];
    
    CCLabelTTF *lbl1= [CCLabelTTF labelWithString:NSLocalizedString(@"retry_game", nil) fontName:@"verdana" fontSize:25];
    CCMenuItemLabel *menuItem1 = [CCMenuItemLabel itemWithLabel:lbl1 target:self selector:@selector(retry)];
    
    CCLabelTTF *lbl2= [CCLabelTTF labelWithString:NSLocalizedString(@"quit_game", nil) fontName:@"verdana" fontSize:20];
    CCMenuItemLabel *menuItem2 = [CCMenuItemLabel itemWithLabel:lbl2 target:self selector:@selector(endGame)];
    
    // Create a menu and add your menu items to it
    CCMenu * myMenu = [CCMenu menuWithItems:logo,menuItem1,menuItem2,nil];
    
    // Arrange the menu items vertically
    [myMenu alignItemsVertically];
    
    // add the menu to your scene
    [self addChild:myMenu];
}


- (void)startGame
{
    [[CCDirector sharedDirector] pushScene:[HelloWorldLayer scene]];
}

- (void)retry
{
    [[CCDirector sharedDirector] replaceScene:[HelloWorldLayer scene]];
}

- (void)endGame
{
    /*while ([[CCDirector sharedDirector] runningScene])
    {
        [[CCDirector sharedDirector] popScene];
    }
    
    [[[CCDirector sharedDirector] runningThread] release];
    exit(0);*/
    
    [[CCDirector sharedDirector] dismissViewControllerAnimated:YES completion:^{
    }];
}

@end
