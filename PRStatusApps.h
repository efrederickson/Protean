@interface PRStatusApps : NSObject
+(void) showIconFor:(NSString*)identifier badgeCount:(int)count;
+(void) hideIconFor:(NSString*)identifier;

+(void) showIconForFlipswitch:(NSString*)identifier;
+(void) forceUpdateForFlipswitch:(NSString*)identifier;

+(void) showIconForBluetooth:(NSString*)identifier;

+(void) reloadAllImages;

+(void) updateTotalNotificationCountIcon; 
@end