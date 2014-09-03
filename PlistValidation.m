//
//  PListValidation.m
//  Created by Michael Cornell on 4/8/14.
//  Beerware License
//
 
 
#import "PListValidation.h"
 
@implementation NSDictionary (PListValidation)
 
//Short form calls
-(BOOL)isValidPList {
    return [NSDictionary validatePList:self];
}
+(BOOL)validatePList:(NSDictionary *)dict {
    return [self validatePList:dict withDepth:0 verbose:NO];
}
// Recursively search through all keys and values of an NSDictionary
+(BOOL)validatePList:(NSDictionary*)dict withDepth:(NSUInteger)depth verbose:(BOOL)verbose{
    NSMutableString *depthSpacer;
    if (verbose){
        depthSpacer = [NSMutableString stringWithString:@""];
        for (int i = 0; i < depth; i++){
            [depthSpacer appendString:@"---"];
        }
        [depthSpacer appendString:@">"];
    }
 
    BOOL isValid = YES;
    for (id key in dict.keyEnumerator) { //iterate through each key
        if (![key isKindOfClass:[NSString class]]){ //all keys must be strings
            if (verbose){
                NSLog(@"PList Validation Failed: All keys must be strings (%@)",[key class]);
            }
            isValid = NO;
            break;
        }
        //Only these classes are allowed as values
        if ((![dict[key] isKindOfClass:[NSData class]]) &&
            (![dict[key] isKindOfClass:[NSDate class]]) &&
            (![dict[key] isKindOfClass:[NSNumber class]]) &&
            (![dict[key] isKindOfClass:[NSString class]]) &&
            (![dict[key] isKindOfClass:[NSArray class]]) &&
            (![dict[key] isKindOfClass:[NSDictionary class]])) {
            if (verbose){
                NSLog(@"PList validation failed: All elements must be: NSData, NSDate, NSNumber, NSString, NSArray, or NSDictionary");
                NSLog(@"Element %@ isn't.",[dict[key] class]);
            }
            isValid = NO;
            break;
        }
        if (verbose){
            NSLog(@"%@ %@(%@):%@",depthSpacer,key,[key class],[dict[key] class]);
        }
 
        //recursive search through sub items
        if ([dict[key] isKindOfClass:[NSArray class]]){
            isValid = [NSArray validatePList:dict[key] withDepth:depth+1 verbose:verbose];
            if (!isValid) {
                break;
            }
        }
        else if ([dict[key] isKindOfClass:[NSDictionary class]]){
            isValid = [self validatePList:dict[key] withDepth:depth+1 verbose:verbose];
            if (!isValid) {
                break;
            }
        }
    }
    return isValid;
}
@end
 
// It's the same thing as NSDictionary, without key validation and a different enumerator
@implementation NSArray (PListValidation)
-(BOOL)isValidPList {
    return [NSArray validatePList:self];
}
+(BOOL)validatePList:(NSArray *)array {
    return [self validatePList:array withDepth:0 verbose:NO];
}
 
+(BOOL)validatePList:(NSArray*)array withDepth:(NSUInteger)depth verbose:(BOOL)verbose{
    NSMutableString *depthSpacer;
    if (verbose){
        depthSpacer = [NSMutableString stringWithString:@""];
        for (int i = 0; i < depth; i++){
            [depthSpacer appendString:@"---"];
        }
        [depthSpacer appendString:@">"];
    }
 
    BOOL isValid = YES;
    for (id item in array){
        if ((![item isKindOfClass:[NSData class]]) &&
            (![item isKindOfClass:[NSDate class]]) &&
            (![item isKindOfClass:[NSNumber class]]) &&
            (![item isKindOfClass:[NSString class]]) &&
            (![item isKindOfClass:[NSArray class]]) &&
            (![item isKindOfClass:[NSDictionary class]])) {
            if (verbose){
                NSLog(@"PList validation failed: All elements must be: NSData, NSDate, NSNumber, NSString, NSArray, or NSDictionary");
                NSLog(@"Element %@ isn't.",item);
            }
            isValid = NO;
            break;
        }
 
        if (verbose){
            NSLog(@"%@ %@",depthSpacer,[item class]);
        }
 
        if ([item isKindOfClass:[NSArray class]]){
            isValid = [self validatePList:item withDepth:depth+1 verbose:verbose];
            if (!isValid) {
                break;
            }
        }
        else if ([item isKindOfClass:[NSDictionary class]]){
            isValid = [NSDictionary validatePList:item withDepth:depth+1 verbose:verbose];
            if (!isValid) {
                break;
            }
        }
    }
    return isValid;
}
@end