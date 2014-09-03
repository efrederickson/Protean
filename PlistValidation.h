//
//  PListValidation.h
//  Created by Michael Cornell on 4/8/14.
//  Beerware License
//
 
// Validates Dictionaries and Arrays to check if they can writeToFile: (and are a valid PList)
#import <Foundation/Foundation.h>
 
@interface NSDictionary (PListValidation)
-(BOOL)isValidPList;
+(BOOL)validatePList:(NSDictionary*)dict;
+(BOOL)validatePList:(NSDictionary*)dict withDepth:(NSUInteger)depth verbose:(BOOL)verbose;
@end
 
@interface NSArray (PListValidation)
-(BOOL)isValidPList;
+(BOOL)validatePList:(NSArray*)array;
+(BOOL)validatePList:(NSArray*)array withDepth:(NSUInteger)depth verbose:(BOOL)verbose;
@end