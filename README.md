# NSObject+Traversal-ObjC

**Language:** Objective-C

Foundation and its support for Key-Value Coding is great for setting and getting values on NSDictionaries at a key path address like `key.subkey`. But KVC falls short when you need to reach into or through an NSArray which is embedded within a dictionary.

For that reason we created a category on NSObject which adds support for setting and getting values at enhanced keypaths, so that if you have an MSMutableDictionary `dictionary` like this:

	NSMutableDictionary *dictionary = [NSMutableDictionary new];
	{
		NSMutableArray *array = [NSMutableArray new];
		{
			NSMutableDictionary *nestedDictionary = [NSMutableDictionary new];
			{
				nestedDictionary[@"subkey"] = aValue;
			}
			[array addObject:nestedDictionary];
		}
		dictionary[@"key"] = array;
	}

you can do stuff like this:

	id theValue = [aDictionary valueForRichKeyPath:@"key.0.subkey"];

and this:

	[aDictionary setValue:anotherValue forAndHydrateRichKeyPath:@"key.0.subkey"];

Isn't that cool?


## Installation

To install, download the source or add this repo as a submodule, and drag `./NSObject+Traversal` into your Xcode project.

## Usage

`NSObject+Traversal.h` exposes the following two methods for rich key path operations:

	- (id)valueForRichKeyPath:(NSString *)keyPath;
	- (void)setValue:(id)value forAndHydrateRichKeyPath:(NSString *)keyPath;

It also provides the following internally used accessors for convenience:

	- (LPObjectType)objectType; // Detects whether the object is a dictionary, array, primitive, or other type	
	- (BOOL)isMutable; // Implements the various -respondsToSelector: checks for mutability

