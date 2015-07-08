//
//  HelloWorldLayer.m
//  SpaceInvaders
//
//  Created by Matt Henkes on 3/28/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//

// Import the interfaces
#import "HelloWorldLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

#import "MenuLayer.h"

// DCSI1_interface
@interface HelloWorldLayer ()
{
    //Ship Sprite
    CCSprite *ship;
    
    //Ship Projectiles
    NSMutableArray *allShipProjectiles;
    int shipProjectileIndex;
    int numberOfShipProjectiles;
    
    //Enemy Projectiles
    NSMutableArray *allEnemyProjectiles;
    int enemyProjectileIndex;
    int numberOfEnemyProjectiles;
    CGFloat enemyFireProbability;
    
    // General
    int leftMargin;
    int rightMargin;
    int shipYPosition;
    
    // Invaders
    NSMutableArray *allInvaderColumns;
    int numberOfInvaderColumns;
    int invaderOffset;
    int invaderXMoveTimeInterval;
    int invaderYMoveTimeInterval;
    int invaderFrameCount;
    CGPoint invaderVelocity;
    int invaderYMoveDistance;
}

// initialize the sprites and position them correctly for the new game
- (void)initializeGame;

// initialize the enemy invaders
- (void)initializeInvaders;

// initailize the ship
- (void)initializeShip;

// get the frames for the enemy sprites
- (void)getSpriteFramesForInvaders:(NSMutableArray *)invaderArray 
                              vics:(NSMutableArray *)vicArray 
                             pings:(NSMutableArray *)pingArray
                             robos:(NSMutableArray *)roboArray;

// add and enemy to an invading column
- (void)addEnemyToColumn:(NSMutableArray *)column
         withSpriteFrame:(CCSpriteFrame *)spriteFrame
           withAnimation:(CCAnimation *)animation
             withXOffset:(NSInteger)xOffset
             withYOffset:(NSInteger)yOffset;

// build projectiles
- (void)initializeProjectiles;

// create an array of invaders in the "front line" invaders that may fire a projectile
- (NSMutableArray *)frontlineInvaders;

// move invaders based on their calculated velocity
- (void)moveAllInvaders;

// determines the next direction for the invaders to move
- (void)determineInvaderVelocity;

// check two sprites to see if they intersect
- (BOOL)checkCollisionOfSprite:(CCSprite *)sprite1 withSprite:(CCSprite *)sprite2;

// check ship sprite aginst collidable objects
- (void)checkShipCollision;

// checks to see if the projectile has hit any invaders
- (void)checkInvaderCollision;

// will return the next projectile to fire for the ship
- (CCSprite *)getNextShipProjectile;

// fires a projectile from the ship
- (void)fireShipProjectile;

// will return the next projectile to fire for the invader
- (CCSprite *)getNextEnemyProjectile;

// each invader in the front line gets a chance to fire a projectile
- (void)fireEnemyProjectile;

// fires a projectile from the invader
- (void)fireEnemyProjectileFromInvader:(CCSprite *)invaderSprite;

@end

#pragma mark - HelloWorldLayer

// HelloWorldLayer implementation
@implementation HelloWorldLayer

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
// Here is the scene it is automatially created by the template
+ (CCScene *)scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

#pragma mark initization

// on "init" you need to initialize your instance
- (id)init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if ((self=[super init]))
    {
        // DCSI1_initContents
        [self initializeGame];
        
        // DCSI2
        //register for touch events
        self.isTouchEnabled = YES;
	}
	return self;
}

// DCSI1_initializeGame
// initialize the sprites and position them correctly for the new game
- (void)initializeGame
{
    [[CCDirector sharedDirector] dismissModalViewControllerAnimated:YES];
    
    //Ship Projectiles
    shipProjectileIndex = 0;
    numberOfShipProjectiles = 3;
    
    //Enemy Projectiles
    enemyProjectileIndex = 0;
    numberOfEnemyProjectiles = 1000;
    enemyFireProbability = 0.01;
    
    // General
    leftMargin = 32;
    rightMargin= [[CCDirector sharedDirector] winSize].width - leftMargin;
    shipYPosition = 50;
    
    // Invaders
    numberOfInvaderColumns = 10;
    invaderOffset = 22;
    invaderXMoveTimeInterval = 360;
    invaderYMoveTimeInterval = 10;
    invaderFrameCount = 0;
    invaderVelocity = CGPointMake(0, 0);
    invaderYMoveDistance = 44;
    
    // DCSI1
    // setup ship
    [self initializeShip];
    
    // DCSI3
    // setup invaders
    [self initializeInvaders];
    
    // DCSI4
    // setup projectiles
    [self initializeProjectiles];
    
    // DCSI3
    // schedule next frame to fire on each frame (approximately 60 times per second)
    [self schedule:@selector(nextFrame:)];
}

// DCSI1_initializeShip
// initailize the ship
- (void)initializeShip
{
    //Find midpoint
    CGFloat midX = [[CCDirector sharedDirector] winSize].width/2;
    
    // Create ship sprite
    ship = [[CCSprite alloc] initWithFile:@"ship.png"];
    
    // set position of ship (relative to center of sprite)
    [ship setPosition:CGPointMake(midX, shipYPosition)];
    
    // add sprite to layer
    [self addChild:ship];
}

// DCSI3_initializeInvaders
// initialize the enemy invaders
- (void)initializeInvaders
{
    // Import sprite sheet
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"spriteMap.plist"];
    
    // Create arrays for individual invader sprite frames
    NSMutableArray *invaderFrames = [NSMutableArray array];
    NSMutableArray *pingFrames = [NSMutableArray array];
    NSMutableArray *vicFrames = [NSMutableArray array];
    NSMutableArray *roboFrames = [NSMutableArray array];
    
    //populate arrays with invader frames
    [self getSpriteFramesForInvaders:invaderFrames vics:vicFrames pings:pingFrames robos:roboFrames];
    
    NSMutableArray *enemyAnimations = [[NSMutableArray alloc] initWithObjects:
                                       [CCAnimation animationWithSpriteFrames:invaderFrames delay:1], 
                                       [CCAnimation animationWithSpriteFrames:vicFrames delay:1], 
                                       [CCAnimation animationWithSpriteFrames:pingFrames delay:1],
                                       [CCAnimation animationWithSpriteFrames:roboFrames delay:1],
                                       nil];
    
    //create array to hold columns of invaders
    allInvaderColumns = [[NSMutableArray alloc] init];
    
    // setup left margin
    int xOffset = leftMargin;
    
    // add invader columns from left to right
    for (int i = 0; i < numberOfInvaderColumns; i++)
    {   
        //create array to hold individual invaders from top to bottom
        NSMutableArray *invaderColumn = [[NSMutableArray alloc] init];
        [allInvaderColumns addObject:invaderColumn];
        
        int yOffset = 0;
        
        // Invader
        [self addEnemyToColumn:invaderColumn withSpriteFrame:[invaderFrames objectAtIndex:0] 
                 withAnimation:[enemyAnimations objectAtIndex:0] withXOffset:xOffset withYOffset:yOffset];
        
        // move down
        yOffset += [[invaderColumn objectAtIndex:0] contentSize].height + invaderOffset;
        
        // Vic
        [self addEnemyToColumn:invaderColumn withSpriteFrame:[vicFrames objectAtIndex:0] 
                 withAnimation:[enemyAnimations objectAtIndex:1] withXOffset:xOffset withYOffset:yOffset];
        
        // move down
        yOffset += [[invaderColumn objectAtIndex:0] contentSize].height + invaderOffset;
        
        // ping
        [self addEnemyToColumn:invaderColumn withSpriteFrame:[pingFrames objectAtIndex:0] 
                 withAnimation:[enemyAnimations objectAtIndex:2] withXOffset:xOffset withYOffset:yOffset];
        
        // move down
        yOffset += [[invaderColumn objectAtIndex:0] contentSize].height + invaderOffset;
        
        // robo
        [self addEnemyToColumn:invaderColumn withSpriteFrame:[roboFrames objectAtIndex:0] 
                 withAnimation:[enemyAnimations objectAtIndex:3] withXOffset:xOffset withYOffset:yOffset];
        
        // move right
        xOffset += [[invaderColumn objectAtIndex:0] contentSize].width + invaderOffset;
    }
}

// DCSI3_getSpriteFramesForInvaders
// get the frames for the enemy sprites
- (void)getSpriteFramesForInvaders:(NSMutableArray *)invaderArray 
                              vics:(NSMutableArray *)vicArray 
                             pings:(NSMutableArray *)pingArray
                             robos:(NSMutableArray *)roboArray
{
    for (int i = 1; i <= 2; ++i)
    {
        // note that we are pulling frames from the cache by name setup in the plist for the sprite sheet
        [invaderArray addObject: [[CCSpriteFrameCache sharedSpriteFrameCache] 
                                   spriteFrameByName:[NSString stringWithFormat:@"eyeGuy%d", i]]];
        [pingArray addObject: [[CCSpriteFrameCache sharedSpriteFrameCache] 
                                spriteFrameByName: [NSString stringWithFormat:@"ping%d", i]]];
        [vicArray addObject: [[CCSpriteFrameCache sharedSpriteFrameCache] 
                               spriteFrameByName: [NSString stringWithFormat:@"vic%d", i]]];
        [roboArray addObject: [[CCSpriteFrameCache sharedSpriteFrameCache] 
                               spriteFrameByName: [NSString stringWithFormat:@"roboDude%d", i]]];
    }
}

// DCSI3_addEnemyToColumn
// add and enemy to an invading column
- (void)addEnemyToColumn:(NSMutableArray *)column
         withSpriteFrame:(CCSpriteFrame *)spriteFrame
           withAnimation:(CCAnimation *)animation
             withXOffset:(NSInteger)xOffset
             withYOffset:(NSInteger)yOffset
{
    // we're creating a sprite from the frame passed in
    CCSprite *enemySprite = [CCSprite spriteWithSpriteFrame:spriteFrame];
    
    // set sprite position (relative to center thus the content size calculations
    [enemySprite setPosition:CGPointMake(xOffset + [enemySprite contentSize].width/2, [[CCDirector sharedDirector] winSize].height - [enemySprite contentSize].height/2 - yOffset)];
    
    // create action to animate the sprite
    [enemySprite runAction:[CCRepeatForever actionWithAction: 
                          [CCAnimate actionWithAnimation:animation]]];
    
    // add sprite to layer
    [self addChild:enemySprite];
    
    // add sprite to column
    [column addObject:enemySprite];
}

// DCSI4_initializeProjectiles
// build projectiles
- (void)initializeProjectiles
{
    // create ship projectile array
    allShipProjectiles = [[NSMutableArray alloc] init];
    
    // create ship projectiles (creating sprites on demand causes a slow down)
    for (int i = 0; i < numberOfShipProjectiles; i++)
    {
        CCSprite *projectile = [CCSprite spriteWithFile:@"projectile.png"];
        [self addChild:projectile];
        [allShipProjectiles addObject:projectile];
    }
    
    // create enemy projectile array
    allEnemyProjectiles = [[NSMutableArray alloc] init];
    
    // create enemy projectiles 
    for (int i = 0; i < numberOfEnemyProjectiles; i++)
    {
        CCSprite *projectile = [CCSprite spriteWithFile:@"projectile.png"];
        [self addChild:projectile];
        [allEnemyProjectiles addObject:projectile];
    }
}

// on "dealloc" you need to release all your retained objects
- (void)dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

// DCSI3_nextFrame
// Code to run for each frame executed
- (void)nextFrame:(ccTime)dt 
{   
    // DCSI3
    // move invaders
    [self moveAllInvaders];
    
    // DCSI4
    // fire enemy projectiles
    [self fireEnemyProjectile];
    
    // DCSI5
    // check for collisions
    [self checkInvaderCollision];
    
    // DCSI5
    // check for collisions
    [self checkShipCollision];
}

#pragma mark Invader Movement
// DCSI3_frontlineInvaders
// create an array of invaders in the "front line" invaders that may fire a projectile
- (NSMutableArray *)frontlineInvaders
{
    NSMutableArray *frontline = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [allInvaderColumns count]; i++) 
    {
        if ([[allInvaderColumns objectAtIndex:i] count] > 0) 
        {
            [frontline addObject:[[allInvaderColumns objectAtIndex:i] lastObject]];
        }        
    }
    
    return frontline;
}

// DCSI3_moveAllInvaders
// move invaders based on their calculated velocity
- (void)moveAllInvaders
{
    // find new? invader velocity
    [self determineInvaderVelocity];
    
    for (int x = 0; x < [allInvaderColumns count]; x++)
    {
        for (int y = 0; y < [[allInvaderColumns objectAtIndex:x] count]; y++) 
        {
            // move each invader on screen
            CCSprite *invader = [[allInvaderColumns objectAtIndex:x] objectAtIndex:y];
            
            // for each sprite apply the velocity to update the invader position
            // not "animated" but it looks like it is because this will happen 60 times per second
            invader.position = CGPointMake(invader.position.x + invaderVelocity.x, invader.position.y + invaderVelocity.y);
        }        
    }
}

// DCSI3_determineInvaderVelocity
// determines the next direction for the invaders to move
- (void)determineInvaderVelocity
{   
    //Is Time Up?
    if (invaderFrameCount == 0) {
        //March if the last movement was not in the x direction
        if (invaderVelocity.x == 0) {
            
            NSMutableArray *frontlineInvaders = [self frontlineInvaders];
            
            // if invaders exist
            if ([frontlineInvaders count]) {
                // find the left corner of the invader block
                CGPoint leftCorner = [[frontlineInvaders objectAtIndex:0] position];
                leftCorner.x -= [[frontlineInvaders objectAtIndex:0] contentSize].width/2;
        
                // find the right corner of the invader block
                CGPoint rightCorner = [[frontlineInvaders lastObject] position];
                rightCorner.x += [[frontlineInvaders lastObject] contentSize].width/2;
        
                // determine the distance from the invader block to the right and left corner of the screen
                CGFloat rightDistance = rightMargin - rightCorner.x;
                CGFloat leftDistance = leftCorner.x - leftMargin;
                CGFloat distance = 0;
            
                // Move in the direction of the greater distance.
                if (rightDistance > leftDistance) {
                    distance = rightDistance;
                }
                else {
                    distance = -leftDistance;
                }
            
                // set the invader velocity to be only in the x direction over time
                invaderVelocity = CGPointMake(distance/invaderXMoveTimeInterval, 0);
            
                // reset the time to complete the movement
                invaderFrameCount = invaderXMoveTimeInterval;
            }
        }
        //Decend
        else
        {
            //set velocity with only a y direction over time to move the invaders down
            invaderVelocity = CGPointMake(0, -invaderYMoveDistance/invaderYMoveTimeInterval);
            
            // reset the time to complete the movement
            invaderFrameCount = invaderYMoveTimeInterval;
        }
    }
    else {
        // if the aloted time has not elapsed retain the previous velocity
        invaderFrameCount--;
    }
}

#pragma mark Collision Detection
// DCSI5_checkCollisionOfSprite
// check two sprites to see if they intersect
- (BOOL)checkCollisionOfSprite:(CCSprite *)sprite1 withSprite:(CCSprite *)sprite2
{
    BOOL collide = NO;
    if (sprite1 && sprite2)
    {
        if (CGRectIntersectsRect([sprite1 boundingBox], [sprite2 boundingBox])) {
            collide = YES;
        }
    }
    
    return collide;
}

// DCSI5_checkShipCollision
// check ship sprite aginst collidable objects
- (void)checkShipCollision
{
    // create and array of all objects that could collide with the ship
    NSMutableArray *collideableObjects = [NSMutableArray arrayWithArray:allEnemyProjectiles];
    [collideableObjects addObjectsFromArray:[self frontlineInvaders]];
    
    for (int i = 0; i < [collideableObjects count]; i++)
    {
        // check each object to see if it has collided with the ship
        if ([self checkCollisionOfSprite:[collideableObjects objectAtIndex:i] withSprite:ship]) 
        {
            // if an object has collied with the ship,
            // the ship has been destroyed and we remove it from the layer
            [self removeChild:ship cleanup:YES];
            ship = nil;
                        
            //DCSI6
            [[CCDirector sharedDirector] pushScene:[MenuLayer sceneWithMenuType:menuTypeLose]];
        }
    }
}

// DCSI5_checkInvaderCollision
// checks to see if the projectile has hit any invaders
- (void)checkInvaderCollision
{
    //Check ship projectiles...
    for (int i = 0; i < numberOfShipProjectiles; i++)
    {
        CCSprite *projectile = [allShipProjectiles objectAtIndex:i];
        
        // against all invader columns...
        for (int x = 0; x < [allInvaderColumns count]; x++)
        {
            // against all sprites in the columns...
            for (int y = 0; y < [[allInvaderColumns objectAtIndex:x] count]; y++)
            {
                CCSprite *invader = [[allInvaderColumns objectAtIndex:x] objectAtIndex:y];
            
                if (invader)
                {
                    // if the projectile and the invaders rect intersect, we have hit the invader and can remove it
                    if ([self checkCollisionOfSprite:projectile withSprite:invader]) 
                    {
                        // remove the projectile from the layer
                        [self removeChild:projectile cleanup:YES];
                        
                        // and hide the projectile off the screen
                        projectile.position = CGPointMake(-1, -1);
                        
                        // remove the invader from the layer
                        [self removeChild:invader cleanup:YES];
                    
                        // remove the invader from the column
                        [[allInvaderColumns objectAtIndex:x] removeObject:invader];
                        
                        invader = nil;
                        
                        // if the column has been emptied of invaders, remove it aswell
                        if ([[allInvaderColumns objectAtIndex:x] count] == 0) 
                        {
                            [allInvaderColumns removeObjectAtIndex:x];
                            
                            //DCSI6
                            // check for game over scenario
                            if ([allInvaderColumns count] == 0) 
                            {   
                                [[CCDirector sharedDirector] pushScene:[MenuLayer sceneWithMenuType:menuTypeWin]];
                            }
                            
                            break;
                        } 
                    }
                }
            }
        }
    }
}

#pragma mark Projectile Creation
// DCSI4_getNextShipProjectile
// will return the next projectile to fire for the ship
- (CCSprite *)getNextShipProjectile
{
    // Grab the next projectile in the array
    CCSprite *projectile = [allShipProjectiles objectAtIndex:shipProjectileIndex];
    
    // increment the projectile index
    shipProjectileIndex++;
    
    // reset the index if needed
    if (shipProjectileIndex == numberOfShipProjectiles)
    {
        shipProjectileIndex = 0;
    }
    
    // if the projectile has not been added to the layer, add it now
    if (![[self children] containsObject:projectile]) 
    {
        [self addChild:projectile];
    }
        
    return projectile;
}

// DCSI4_fireShipProjectile
// fires a projectile from the ship
- (void)fireShipProjectile
{
    // grab the next projectile sprite
    CCSprite *projectile = [self getNextShipProjectile];
    
    // has this sprite already been fired (and has not yet completed it's animation)?
    if ([projectile numberOfRunningActions] > 0)
    {
        // if so return without firing the projectile
        return;
    }
    
    // find the position of the ship
    CGPoint shipPosition = [ship position];
    
    // adjust the postion to start the projectile from the top of the ship
    shipPosition.y += [ship contentSize].height/2 + [projectile contentSize].height/2;
    
    // set the position of the projectile sprite
    [projectile setPosition:shipPosition];

    // create and end point for the projectile to travel to.
    // we use the height of the window plus the ship postion to ensure the projectile travels off screen at a constant velocity
    CGPoint endPoint = CGPointMake(shipPosition.x, shipPosition.y + [[CCDirector sharedDirector] winSize].height);
    
    // set the projectile to run the "MoveTo" action in 2 seconds
    [projectile runAction:[CCMoveTo actionWithDuration:2 position:endPoint]];
}

// DCSI4_getNextEnemyProjectile
// will return the next projectile to fire for the invader
- (CCSprite *)getNextEnemyProjectile
{
    // Grab the next projectile in the array
    CCSprite *projectile = [allEnemyProjectiles objectAtIndex:enemyProjectileIndex];
    
    // increment the projectile index
    enemyProjectileIndex++;
    if (enemyProjectileIndex == numberOfEnemyProjectiles)
    {
        enemyProjectileIndex = 0;
    }
    
    // if the projectile has not been added to the layer, add it now
    if (![[self children] containsObject:projectile]) 
    {
        [self addChild:projectile];
    }
    
    return projectile;
}

// DCSI4_fireEnemyProjectile
// each invader in the front line gets a chance to fire a projectile
- (void)fireEnemyProjectile
{   
    // for each invader in the front line
    for (CCSprite *bottomInvader in [self frontlineInvaders]) 
    {
        // find a random number
        int random = rand() % 100000;
        
        // if the random number is within tolerence fire the projectile
        if (random < (enemyFireProbability) * 100000)
        {                    
            [self fireEnemyProjectileFromInvader:bottomInvader];
        }
    }
}

// DCSI4_fireEnemyProjectileFromInvader
// fires a projectile from the invader
- (void)fireEnemyProjectileFromInvader:(CCSprite *)invaderSprite
{
    // grab the next projectile sprite
    CCSprite *projectile = [self getNextEnemyProjectile];
    
    // has this sprite already been fired (and has not yet completed it's animation)?
    if ([projectile numberOfRunningActions] > 0)
    {
        return;
    }
    
    // find the position of the invader
    CGPoint invaderPosition = [invaderSprite position];
    
    // adjust the postion to start the projectile from the bottom of the invader
    invaderPosition.y -= [invaderSprite contentSize].height/2 + [projectile contentSize].height/2;
    
    // set the position of the projectile sprite
    [projectile setPosition:invaderPosition];
    
    // create and end point for the projectile to travel to.
    // we use the height of the window plus the ship postion to ensure the projectile travels off screen at a constant velocity
    CGPoint endPoint = CGPointMake(invaderPosition.x, invaderPosition.y - [[CCDirector sharedDirector] winSize].height);
    
    // set the projectile to run the "MoveTo" action in 2 seconds
    [projectile runAction:[CCMoveTo actionWithDuration:3 position:endPoint]];
}

#pragma mark Touch Events

// DCSI2_registerWithTouchDispatcher
// tell the CCLayer code that we want the “targeted” set of touch events rather than the “standard” set
- (void)registerWithTouchDispatcher
{
    CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

// DCSI2_ccTouchBegan
// when the user taps the screen, fire a missile and move the ship the correct direction
- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGRect shipRect = [ship boundingBox];
    
    // Inflate rect
    // Tyler, if we are doubleing the size of the rect lets not had code number =D
    shipRect.size.width += 120;
    shipRect.size.height += 120;
    shipRect.origin.x -= 60;
    shipRect.origin.y -= 60;
    
    // Convert the touch into node space
    CGPoint touchPoint = [self convertTouchToNodeSpace:touch];
    
    // check to see if the touch is within the expanded ship rect
    if (CGRectContainsPoint(shipRect, touchPoint)) 
    {
        //if so fire a projectile
        [self fireShipProjectile];
        // and schedule a projectile to fire every subsequent second
        [self schedule:@selector(fireShipProjectile) interval:1];
        
        return YES;
    }
    
    return NO;
}

// DCSI2_ccTouchEnded
// when the user stops touching the screen
- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    // stop firing the projectile
    [self unschedule:@selector(fireShipProjectile)];
}

// DCSI2_ccTouchCancelled
// when the touch is cancelled (however that happens)
-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
    // stop firing the projectileß
    [self unschedule:@selector(fireShipProjectile)];
}

// DCSI2_ccTouchMoved
// when an existing touch moves
-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Convert the touch into node space
    CGPoint location = [self convertTouchToNodeSpace:touch];
    
    // do not allow the ship to move in the Y direction
    location.y = shipYPosition;
    
    // update the ship location.
    ship.position = location;        
}
                                         
@end
