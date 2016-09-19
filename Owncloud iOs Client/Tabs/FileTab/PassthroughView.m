//
//  PassthroughView.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 08/10/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import "PassthroughView.h"

@implementation PassthroughView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

///-----------------------------------
/// @name Point Inside
///-----------------------------------

/**
 * We overwrite this method in order to pass the point and the event in this view to the next view
 *
 * @param point -> CGPoint (point in the screen)
 * @param event -> UIEvent (touch, tap, swipe..)
 *
 *
 * @return BOOL -> YES/NOT
 *
 */
-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    for (UIView *view in self.subviews) {
        if (!view.hidden && view.userInteractionEnabled && [view pointInside:[self convertPoint:point toView:view] withEvent:event])
            return YES;
    }
    return NO;
}

@end
