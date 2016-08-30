//
//  NSObject+AssociatedObject.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 4/12/15.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import "NSObject+AssociatedObject.h"

#import <objc/runtime.h>

@implementation NSObject (AssociatedObject)

- (void)setAssociatedObject:(id)associatedObject
{

    objc_setAssociatedObject(self,
                             @selector(associatedObject),
                             associatedObject,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)associatedObject
{
     return objc_getAssociatedObject(self, @selector(associatedObject));
}

@end
