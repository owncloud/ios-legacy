//
//  CWLOrderedDictionary.m
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

#import "CWLOrderedDictionary.h"

NSString *DescriptionForObject(NSObject *object, id locale, NSUInteger indent)
{
    NSString *objectString;
    if ([object isKindOfClass:[NSString class]])
    {
        objectString = (NSString *)object;
    }
    else if ([object respondsToSelector:@selector(descriptionWithLocale:indent:)])
    {
        objectString = [(NSDictionary *)object descriptionWithLocale:locale indent:indent];
    }
    else if ([object respondsToSelector:@selector(descriptionWithLocale:)])
    {
        objectString = [(NSSet *)object descriptionWithLocale:locale];
    }
    else
    {
        objectString = [object description];
    }
    return objectString;
}

@implementation CWLOrderedDictionary

- (id)init
{
    return [self initWithCapacity:0];
}

- (id)initWithCapacity:(NSUInteger)capacity
{
    self = [super init];
    if (self != nil)
    {
        dictionary = [[NSMutableDictionary alloc] initWithCapacity:capacity];
        keyset = [[NSMutableOrderedSet alloc] initWithCapacity:capacity];
    }
    return self;
}

- (id)copy
{
    return [self mutableCopy];
}

- (void)setObject:(id)anObject forKey:(id)aKey
{
    if (![keyset containsObject:aKey])
    {
        [keyset addObject:aKey];
    }
    [dictionary setObject:anObject forKey:aKey];
}

- (void)removeObjectForKey:(id)aKey
{
    [dictionary removeObjectForKey:aKey];
    [keyset removeObject:aKey];
}

- (NSUInteger)count
{
    return [dictionary count];
}

- (id)objectForKey:(id)aKey
{
    return [dictionary objectForKey:aKey];
}

- (NSEnumerator *)keyEnumerator
{
    return [keyset objectEnumerator];
}

- (NSEnumerator *)reverseKeyEnumerator
{
    return [keyset reverseObjectEnumerator];
}

- (void)insertObject:(id)anObject forKey:(id)aKey atIndex:(NSUInteger)anIndex
{
    if ([dictionary objectForKey:aKey])
    {
        [keyset removeObject:aKey];
    }
    [keyset insertObject:aKey atIndex:anIndex];
    [dictionary setObject:anObject forKey:aKey];
}

- (id)keyAtIndex:(NSUInteger)anIndex
{
    return [keyset objectAtIndex:anIndex];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len
{
    return [keyset countByEnumeratingWithState: state
                                       objects: stackbuf
                                         count: len];
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    id key = [keyset objectAtIndex:idx];

    return [dictionary objectForKey:key];
}

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
    //NSAssert (idx <= keyset.count -1, @"index %ld is beyond max range %ld", idx, keyset.count - 1);

    id key = [keyset objectAtIndex:idx];
    [dictionary setObject:obj forKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key
{
    [self setObject:obj forKey:key];
}

- (id)objectForKeyedSubscript:(id)key
{
    return [dictionary objectForKey:key];
}

- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level
{
    NSMutableString *indentString = [NSMutableString string];
    NSUInteger i, count = level;
    for (i = 0; i < count; i++)
    {
        [indentString appendFormat:@"    "];
    }

    NSMutableString *description = [NSMutableString string];
    [description appendFormat:@"%@{\n", indentString];
    for (NSObject *key in self)
    {
        [description appendFormat:@"%@    %@ = %@;\n",
         indentString,
         DescriptionForObject(key, locale, level),
         DescriptionForObject([self objectForKey:key], locale, level)];
    }
    [description appendFormat:@"%@}\n", indentString];
    return description;
}

@end
