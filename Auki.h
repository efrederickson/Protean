@class BBBulletin;

@interface KJUARR : NSObject
+(BOOL)doUrThing:(BBBulletin *)bulletin;
+(BOOL)doUrThing:(BBBulletin *)bulletin withImages:(NSArray *)images;
+(BOOL)doUrThing:(BBBulletin *)bulletin withRecipients:(NSArray *)recipients;
+(BOOL)doUrThing:(BBBulletin *)bulletin withImages:(NSArray *)images recipients:(NSArray *)recipients;
@end