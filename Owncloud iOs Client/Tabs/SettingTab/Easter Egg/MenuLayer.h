//
//  WinLayer.h
//  SpaceInvaders
//
//  Created by Tyler Biethman on 5/27/12.
//  Copyright 2012 Cerner Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

extern NSString *const menuTypeWelcome;
extern NSString *const menuTypeWin;
extern NSString *const menuTypeLose;

@interface MenuLayer : CCLayer

+ (CCScene *)sceneWithMenuType:(NSString *)type;

- (void)createIntroductionMenu;

- (void)createWinMenu;

- (void)createLoseMenu;

@end
