//
//  CWLOrderedDictionary.h
//  OrderedDictionary
//
//  Created by Matt Gallagher on 19/12/08.
//  Maintainer:Kazuto Yamasaki<kazuto_yamasaki@pokelabo.co.jp>
//  Copyright 2008 Matt Gallagher.
//            2012 ilja.
//            2013 Kazuto Yamasaki<kazuto_yamasaki@pokelabo.co.jp>.
//  All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software. Permission is granted to anyone to
//  use this software for any purpose, including commercial applications, and to
//  alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source
//     distribution.
//

@interface CWLOrderedDictionary : NSMutableDictionary
{
    NSMutableDictionary *dictionary;
    NSMutableOrderedSet*keyset;
}

- (void)setObject:(id)anObject forKey:(id)aKey;
- (NSUInteger) count;
- (id)objectForKey:(id)aKey;

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx;
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;
- (id)objectForKeyedSubscript:(id)key;

- (void)insertObject:(id)anObject forKey:(id)aKey atIndex:(NSUInteger)anIndex;
- (id)keyAtIndex:(NSUInteger)anIndex;
- (NSEnumerator *)reverseKeyEnumerator;

@end
