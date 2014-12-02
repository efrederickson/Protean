// The purpose of this is to help LibStatusBar search for icons in Protean’s search paths/bundles and flipswitches too

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <flipswitch/Flipswitch.h>
#import "Protean.h"

//__strong NSMutableDictionary *cache = [NSMutableDictionary dictionary];
NSCache *cache = [[NSCache alloc] init];


// This is... bad... 
// But, it works. Which is what i need. 
// TODO: better hack

%hook UIImage
+(id) kitImageNamed:(NSString*)name
{
    @autoreleasepool {
        CHECK_ENABLED(%orig);
        if (name == nil)
        	return %orig;

        if ([cache objectForKey:name] != nil)
            return [cache objectForKey:name];
        id _tmp = %orig;
        if (_tmp)
            return _tmp;

        NSString *patchedName = name;
        
        if ([name hasPrefix:@"White_"])
            patchedName = [name substringFromIndex:6];
        else if ([name hasPrefix:@"Black_"])
            patchedName = [name substringFromIndex:6];
        else if ([name hasPrefix:@"LockScreen_"])
            patchedName = [name substringFromIndex:11];
            
        if ([patchedName hasSuffix:@"_Color"])
            return nil;
            //patchedName = [patchedName substringToIndex:patchedName.length - 6];
            
        NSString *patchedName2 = patchedName;
        if ([patchedName hasPrefix:@"PR_"])
            patchedName2 = [patchedName substringFromIndex:3];

        NSString *fsName = [NSString stringWithFormat:@"/Library/Protean/protean-fscache/%@-%@.png",patchedName2,
            [[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:patchedName2] == FSSwitchStateOn ? @"on" : @"off"];
        UIImage *image = [UIImage imageWithContentsOfFile:fsName];
        if (image)
        {
            [cache setObject:image forKey:fsName];
            return image;
        }

        if (!image)
            image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/Protean/Images.bundle/%@.png", patchedName]];

        //NSLog(@"[Protean] %@", [NSString stringWithFormat:@"/tmp/protean/%@.png", patchedName]);
        if (!image)
            image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/Protean/TranslatedVectors~cache/%@.png", patchedName]];

        if (!image)
        {
            image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/Frameworks/UIKit.framework/%@.png",name]];
        }

        if (image)
            [cache setObject:image forKey:name];

        return image;
    }
}
%end

_UILegibilityImageSet* getContentsImage(UIStatusBarItemView *self)
{
	UIStatusBarForegroundStyle* fs = [self foregroundStyle];
	UIColor* tintColor = [fs tintColor];
	int type = ((UIStatusBarItemView*)self).item.type;
	NSString* itemName = [Protean imageNameForIdentifier:[NSString stringWithFormat:@"%d",type]];

	if (itemName == nil || [itemName isEqual:@""])
		return nil;

	NSString* expandedName_default = [fs expandedNameForImageName: itemName];
	
	bool isBlack = [tintColor isEqual: [UIColor blackColor]];
	bool isLockscreen = [fs isKindOfClass:objc_getClass("UIStatusBarLockScreenForegroundStyleAttributes")];
	
	UIImage* image_color = [UIImage kitImageNamed: [NSString stringWithFormat: @"%@_%@_Color", isLockscreen?  @"LockScreen" : isBlack ? @"Black" : @"White", itemName]];
	UIImage* image_base = image_color ? 0 : [UIImage kitImageNamed: expandedName_default];
	
	UIImage* image = image_color;
	if(!image && image_base)
	{
		image = [image_base _flatImageWithColor: tintColor];
	}
	_UILegibilityImageSet* ret = [_UILegibilityImageSet imageFromImage: image withShadowImage: nil];//image_sh];
	
	return ret;
}

%hook UIStatusBarIndicatorItemView
-(_UILegibilityImageSet*) contentsImage
{
	return getContentsImage((UIStatusBarItemView*)self) ?: %orig;
}
%end

%hook UIStatusBarQuietModeItemView
-(_UILegibilityImageSet*) contentsImage
{
	return getContentsImage((UIStatusBarItemView*)self) ?: %orig;
}
%end

%hook UIStatusBarAirplaneModeItemView
-(_UILegibilityImageSet*) contentsImage
{
	return getContentsImage((UIStatusBarItemView*)self) ?: %orig;
}
%end

%hook UIStatusBarBluetoothItemView
-(_UILegibilityImageSet*) contentsImage
{
	return getContentsImage((UIStatusBarItemView*)self) ?: %orig;
}
%end

%hook UIStatusBarLocationItemView
-(_UILegibilityImageSet*) contentsImage
{
	return getContentsImage((UIStatusBarItemView*)self) ?: %orig;
}
%end
