#import "common.h"

@interface Protean : NSObject

+(BOOL) canHandleTapForItem:(UIStatusBarItem*)item;
+(id) HandlerForTapOnItem:(UIStatusBarItem*)item;

+(void) mapIdentifierToItem:(NSString*)identifier item:(int)type;
+(NSString*) mappedIdentifierForItem:(int)type;
+(void) mapIdentifierToItem:(NSString*)identifier;

+(NSString*)imageNameForIdentifier:(NSString*)identifier;
+(NSString*)imageNameForIdentifier:(NSString*)identifier withBadgeCount:(int)count;

+(NSMutableDictionary*) getOrLoadSettings;

+(void) addBulletin:(BBBulletin*)bulletin forApp:(NSString*)appId;

+(void) reloadSettings;
@end