//
//  NSObject+Traversal.h
//  NSObject+Traversal
//
//  Created by Paul Shapiro on 11/10/14.
//  Copyright (c) 2016 Lunarpad Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, LPObjectType)
{
    LPObjectTypeArray,
    LPObjectTypeDictionary,
    LPObjectTypePrimitive,
    LPObjectTypeUnknown
};

@interface NSObject (Traversal)

- (id)valueForRichKeyPath:(NSString *)keyPath;
- (void)setValue:(id)value forAndHydrateRichKeyPath:(NSString *)keyPath;

- (LPObjectType)objectType;
- (BOOL)isMutable; // this will look up the type with -objectType and call -_isMutableGivenType:. for a slight potential optimization, cache the object type and call -_isMutableGivenType: directly
- (BOOL)_isMutableGivenType:(LPObjectType)type; // for arrays, checks if can insert. otherwise, checks if responds to setValue:forKeyPath:

@end
