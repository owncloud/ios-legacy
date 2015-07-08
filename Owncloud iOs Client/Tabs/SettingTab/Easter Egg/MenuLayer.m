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
	}
    
	return self;
}

- (void)createIntroductionMenu
{    
    // Create some menu items
    CCMenuItemImage * menuItem1 = [CCMenuItemImage itemWithNormalImage:@"new_game_default.png"
                                                         selectedImage:@"new_game_selected.png"
                                                                target:self
                                                              selector:@selector(startGame)];
    
    CCMenuItemImage * menuItem2 = [CCMenuItemImage itemWithNormalImage:@"quit_default.png"
                                                         selectedImage:@"quit_selected.png"
                                                                target:self
                                                              selector:@selector(endGame)];
    
    // Create a menu and add your menu items to it
    CCMenu * myMenu = [CCMenu menuWithItems:menuItem1,menuItem2,nil];
    
    // Arrange the menu items vertically
    [myMenu alignItemsVertically];
    
    // add the menu to your scene
    [self addChild:myMenu];
}

- (void)createWinMenu
{    
    // Create some menu items
    CCMenuItemImage * menuItem1 = [CCMenuItemImage itemWithNormalImage:@"play_again_default.png"
                                                         selectedImage:@"play_again_selected.png"
                                                                target:self
                                                              selector:@selector(retry)];
    
    CCMenuItemImage * menuItem2 = [CCMenuItemImage itemWithNormalImage:@"quit_default.png"
                                                         selectedImage:@"quit_selected.png"
                                                                target:self
                                                              selector:@selector(endGame)];
    
    // Create a menu and add your menu items to it
    CCMenu * myMenu = [CCMenu menuWithItems:menuItem1,menuItem2,nil];
    
    // Arrange the menu items vertically
    [myMenu alignItemsVertically];
    
    // add the menu to your scene
    [self addChild:myMenu];
}

- (void)createLoseMenu
{    
    // Create some menu items
    CCMenuItemImage * menuItem1 = [CCMenuItemImage itemWithNormalImage:@"retry_default.png"
                                                         selectedImage:@"retry_selected.png"
                                                                target:self
                                                              selector:@selector(retry)];
    
    CCMenuItemImage * menuItem2 = [CCMenuItemImage itemWithNormalImage:@"quit_default.png"
                                                         selectedImage:@"quit_selected.png"
                                                                target:self
                                                              selector:@selector(endGame)];
    
    // Create a menu and add your menu items to it
    CCMenu * myMenu = [CCMenu menuWithItems:menuItem1,menuItem2,nil];
    
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
    while ([[CCDirector sharedDirector] runningScene]) 
    {
        [[CCDirector sharedDirector] popScene];
    }
    
    [[[CCDirector sharedDirector] runningThread] release];
    exit(0);
}

@end
