//
//  NSObject+Traversal.m
//  NSObject+Traversal
//
//  Created by Paul Shapiro on 11/10/14.
//  Copyright (c) 2016 Lunarpad Corporation. All rights reserved.
//

#import "NSObject+Traversal.h"

@implementation NSObject (Traversal)


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Accessors - Transforms

- (LPObjectType)objectType
{
    if ([self isKindOfClass:[NSDictionary class]]) {
        return LPObjectTypeDictionary;
    } else if ([self isKindOfClass:[NSArray class]]) {
        return LPObjectTypeArray;
    } else if ([self isKindOfClass:[NSString class]] || [self isKindOfClass:[NSNumber class]]) {
        return LPObjectTypePrimitive;
    }
    
    return LPObjectTypeUnknown;
}

- (BOOL)isMutable
{
    return [self _isMutableGivenType:[self objectType]];
}

- (BOOL)_isMutableGivenType:(LPObjectType)type
{
    switch (type) {
        case LPObjectTypeArray:
            return [self respondsToSelector:@selector(setObject:atIndex:)];
            
        case LPObjectTypePrimitive:
            return NO;

        case LPObjectTypeDictionary:
        case LPObjectTypeUnknown:
        default:
            return [self respondsToSelector:@selector(setValue:forKeyPath:)];
    }
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Accessors - Lookups

- (id)valueForRichKeyPath:(NSString *)keyPath
{
    LPObjectType type = [self objectType];

    return [self _valueForRichKeyPath:keyPath givenType:type];
}

- (id)_valueForRichKeyPath:(NSString *)keyPath givenType:(LPObjectType)type
{
    if (type == LPObjectTypePrimitive) {
        NSLog(@"Warn: Asked to return %@ %@ for primitive type.", NSStringFromSelector(_cmd), keyPath);
        
        return self;
    }
    const char *keyPathCString = [keyPath UTF8String];
    const char *ptrToFirstPeriod = strchr(keyPathCString, '.');
    if (!ptrToFirstPeriod) {
        return [self _valueForRootKey:keyPath givenType:type];
    }
    NSUInteger indexOfFirstPeriod = ptrToFirstPeriod - keyPathCString;
    NSString *keyPathRootKey = [keyPath substringToIndex:indexOfFirstPeriod];
    id rootKeyValue = [self _valueForRootKey:keyPathRootKey givenType:type];
    if (!rootKeyValue) {
        return nil;
    }
    NSString *remainingKeyPathString = [keyPath substringFromIndex:indexOfFirstPeriod + 1]; // +1 to skip the period
    
    return [rootKeyValue valueForRichKeyPath:remainingKeyPathString]; // due to the check for absence of period earlier, we know here that we are not at a parent collection of a terminal node, and we still have levels to traverse
}

- (id)_valueForRootKey:(NSString *)rootKey givenType:(LPObjectType)type
{
    switch (type) {
        case LPObjectTypeArray:
        {
            NSUInteger intFromKeyPathRootKey = [rootKey integerValue];
            NSArray *array = (NSArray *)self;
            if (array.count > intFromKeyPathRootKey) {
                return [array objectAtIndex:intFromKeyPathRootKey];
            } else {
                return nil;
            }
        }
            
        case LPObjectTypeDictionary:
        case LPObjectTypeUnknown:
        {
            return [self valueInDictionaryForRichKey:rootKey];
        }
            
        default:
        { // We should never get here
            break;
        }
    }
    
    return nil;
}

- (id)valueInDictionaryForRichKey:(NSString *)rootKey
{
    return [self valueForKeyPath:rootKey]; // use keyPath method because of 'Unknown' type having to implement it to get support
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Imperatives

- (void)setValue:(id)value forAndHydrateRichKeyPath:(NSString *)keyPath
{
    LPObjectType type = [self objectType];
    BOOL isMutable = [self _isMutableGivenType:type];
    if (!isMutable) {
        return;
    }
    if (type == LPObjectTypePrimitive) { // This should be caught by the isMutable check, but just in case……
        NSLog(@"Error: Asked to %@ at %@ on a primitive, %@", NSStringFromSelector(_cmd), keyPath, self);
        
        return;
    }
    const char *keyPathCString = [keyPath UTF8String];
    const char *ptrToFirstPeriod = strchr(keyPathCString, '.');
    if (!ptrToFirstPeriod) {
        [self __setValueAsParentCollectionOfTerminalNode:value withRootKey:keyPath givenType:type]; // We are at a parent collection of a terminal node
        
        return;
    }
    NSUInteger indexOfFirstPeriod = ptrToFirstPeriod - keyPathCString;
    NSString *keyPathRootKey = [keyPath substringToIndex:indexOfFirstPeriod];
    id rootKeyValue = [self _valueForRichKeyPath:keyPathRootKey givenType:type];
    
    NSString *remainingKeyPathString = [keyPath substringFromIndex:indexOfFirstPeriod + 1]; // +1 to skip the period
    if (remainingKeyPathString.length) {
        if (!rootKeyValue) {
            rootKeyValue = [NSMutableDictionary new];
            [self __setValueAsParentCollectionOfTerminalNode:rootKeyValue withRootKey:keyPathRootKey givenType:[rootKeyValue objectType]]; // We are at a parent collection of a terminal node
        }
        [rootKeyValue setValue:value forAndHydrateRichKeyPath:remainingKeyPathString];
        
        return;
    }
    
    NSLog(@"Error: There was a period in that keypath %@ but there was nothing after the period!", keyPath);
}

- (void)__setValueAsParentCollectionOfTerminalNode:(id)value withRootKey:(NSString *)rootKey givenType:(LPObjectType)type
{
    switch (type) {
        case LPObjectTypeDictionary:
        {
            if (value == nil) {
                [(NSMutableDictionary *)self removeObjectForKey:rootKey];
            } else {
                [self setValue:value forKey:rootKey];
            }
            
            break;
        }

        case LPObjectTypeUnknown:
        { // using setValue:forKeyPath: specifically for Unknown type because those objects will have the keyPath method implemented
            if (value == nil) {
                [self setValue:value forKeyPath:rootKey];
            } else {
                [self setValue:value forKeyPath:rootKey];
            }
            
            break;
        }
            
        case LPObjectTypeArray:
        {
            NSUInteger intFromKeyPathRootKey = [rootKey integerValue];
            NSMutableArray *array = (NSMutableArray *)self;
            if (array.count > intFromKeyPathRootKey) {
                [array replaceObjectAtIndex:intFromKeyPathRootKey withObject:value];
            } else {
                // Inserting padding up until intFromKeyPathRootKey, then adding the value on top of that
                NSUInteger numberOfSpacesToAdd = array.count - intFromKeyPathRootKey;
                if (numberOfSpacesToAdd) {
                    id paddingObject = [NSDictionary new];
                    for (int i = 0 ; i < numberOfSpacesToAdd ; i++) {
                        [array addObject:paddingObject];
                    }
                }
                [array addObject:value];
            }
            
            
            break;
        }
            
        default:
        { // We should never get here
            break;
        }
    }
}

@end
