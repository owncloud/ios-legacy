//
//  AssetCell.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetCell.h"
#import "ELCAsset.h"

@interface ELCAssetCell ()

@property (nonatomic, retain) NSArray *rowAssets;
@property (nonatomic, retain) NSMutableArray *imageViewArray;
@property (nonatomic, retain) NSMutableArray *overlayViewArray;

@end

@implementation ELCAssetCell

@synthesize rowAssets = _rowAssets;

- (id)initWithAssets:(NSArray *)assets reuseIdentifier:(NSString *)identifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
	if(self) {
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped:)];
        [self addGestureRecognizer:tapRecognizer];
        [tapRecognizer release];
        
        NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.imageViewArray = mutableArray;
        [mutableArray release];
        
        NSMutableArray *overlayArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.overlayViewArray = overlayArray;
        [overlayArray release];

        [self setAssets:assets];
	}
	return self;
}

- (void)setAssets:(NSArray *)assets
{
    self.rowAssets = assets;
	for (UIView *view in [self subviews]) {
        if ([view isKindOfClass:UIImageView.class]) {
            [view removeFromSuperview];
        }
	}
    
    //set up a pointer here so we don't keep calling [UIImage imageNamed:] if creating overlays
    UIImage *overlayImage = nil;
    for (int i = 0; i < [_rowAssets count]; ++i) {

        ELCAsset *asset = [_rowAssets objectAtIndex:i];
        
        if (i < [_imageViewArray count]) {
            UIImageView *imageView = [_imageViewArray objectAtIndex:i];
            imageView.image = [UIImage imageWithCGImage:asset.asset.thumbnail];
        } else {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:asset.asset.thumbnail]];
            [_imageViewArray addObject:imageView];
            [imageView release];
        }
        
        if (i < [_overlayViewArray count]) {
            UIImageView *overlayView = [_overlayViewArray objectAtIndex:i];
            overlayView.hidden = asset.selected ? NO : YES;
        } else {
            if (overlayImage == nil) {
                overlayImage = [UIImage imageNamed:@"imageSelected.png"];
            }
            UIImageView *overlayView = [[UIImageView alloc] initWithImage:overlayImage];
            [_overlayViewArray addObject:overlayView];
            overlayView.hidden = asset.selected ? NO : YES;
            [overlayView release];
        }
    }
}

- (void)cellTapped:(UITapGestureRecognizer *)tapRecognizer
{
    CGPoint point = [tapRecognizer locationInView:self];
    //CGFloat totalWidth = self.rowAssets.count * 75 + (self.rowAssets.count - 1) * 4;
    
    //We calculate the sizes supousing the cells have 78px becaouse have 2 of margins
    CGFloat totalWidth = ((int)(self.bounds.size.width/78)) * 78;
    CGFloat startX = (self.bounds.size.width - totalWidth) / 2;
    
	CGRect frame = CGRectMake(startX, 2, 75, 75);
	
	for (int i = 0; i < [_rowAssets count]; ++i) {
        if (CGRectContainsPoint(frame, point)) {
            ELCAsset *asset = [_rowAssets objectAtIndex:i];
            asset.selected = !asset.selected;
            UIImageView *overlayView = [_overlayViewArray objectAtIndex:i];
            overlayView.hidden = !asset.selected;
            break;
        }
        frame.origin.x = frame.origin.x + frame.size.width + 4;
    }
}

- (void)layoutSubviews
{
    //CGFloat totalWidth = self.rowAssets.count * 75 + (self.rowAssets.count - 1) * 4;
    
    //We calculate the sizes supousing the cells have 78px becaouse have 2 of margins
    CGFloat totalWidth = ((int)(self.bounds.size.width/78)) * 78;
    CGFloat startX = (self.bounds.size.width - totalWidth) / 2;
    
    
	CGRect frame = CGRectMake(startX, 2, 75, 75);
	
	for (int i = 0; i < [_rowAssets count]; ++i) {
        
        ELCAsset *asset = [_rowAssets objectAtIndex:i];
        UIView *currentVideoView = nil;
        
        if ([[asset.asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
            //Base View
            currentVideoView = [[UIView alloc] initWithFrame:CGRectMake(frame.origin.x, frame.origin.y+60, frame.size.width, frame.size.height-60)];
            currentVideoView.backgroundColor = [UIColor blackColor];
            currentVideoView.alpha = 0.7f;
            
            // Movie icon on left side
            CGRect movieFrame = CGRectMake(5, 2, 15, 10);
            UIImageView *movieImageView = [[UIImageView alloc] initWithFrame:movieFrame];
            movieImageView.image=[UIImage imageNamed:@"movieOverlay.png"];
            [currentVideoView addSubview:movieImageView];
            
            [movieImageView release];
            
            //Duration
            if ([asset.asset valueForProperty:ALAssetPropertyDuration] != ALErrorInvalidProperty) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"mm:ss"];
                CGRect durationFrame = CGRectMake(45,2, 30, 10);
                UILabel *durationView = [[UILabel alloc] initWithFrame:durationFrame];
                durationView.backgroundColor = [UIColor clearColor];
                durationView.textColor = [UIColor whiteColor];
                durationView.font = [UIFont systemFontOfSize:10];
                NSString *videoDuration= [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[[asset.asset valueForProperty:ALAssetPropertyDuration] doubleValue]]];
                //DLog(@"Video with duration: %@", videoDuration);
                durationView.text=videoDuration;
                [currentVideoView addSubview:durationView];
               
                [formatter release];
                [durationView release];
            }
        }
        
		UIImageView *imageView = [_imageViewArray objectAtIndex:i];
        [imageView setFrame:frame];
		
        [self addSubview:imageView];
        
        UIImageView *overlayView = [_overlayViewArray objectAtIndex:i];
        [overlayView setFrame:frame];
        [self addSubview:overlayView];
        
        if (currentVideoView) {
            [self addSubview:currentVideoView];
        }
		
        [currentVideoView release];
        
		frame.origin.x = frame.origin.x + frame.size.width + 4;
	}
}

- (void)dealloc
{
	[_rowAssets release];
    [_imageViewArray release];
    [_overlayViewArray release];
	[super dealloc];
}

@end
