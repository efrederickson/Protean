@interface PRStatusApps : NSObject
+(void) showIconFor:(NSString*)identifier badgeCount:(int)count;
+(void) hideIconFor:(NSString*)identifier;

+(void) showIconForFlipswitch:(NSString*)identifier;

+(void) showIconForBluetooth:(NSString*)identifier;

+(void) reloadAllImages;

+(void) updateTotalNotificationCountIcon; 

+(void) updateCachedBadgeCount:(NSString*)identifier count:(int) count;
+(void) updateNCStatsForIcon:(NSString*)section count:(int)count;
+(int) ncCount:(NSString*)identifier;
+(void) updateLockState:(BOOL) state;
@end