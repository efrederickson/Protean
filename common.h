#import "headers.h"

#define CHECK_ENABLED(x) \
id _enabled = [Protean getOrLoadSettings][@"enabled"]; \
if ((_enabled ? [_enabled boolValue] : YES) == NO) \
    return x;

#define CHECK_ENABLED2(x) \
id _enabled = [Protean getOrLoadSettings][@"enabled"]; \
if ((_enabled ? [_enabled boolValue] : YES) == NO) { \
x; \
return;\
}

#define LIBSTATUSBAR8 ([NSFileManager.defaultManager fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/libstatusbar8.dylib"])

#define SYSTEM_VERSION_EQUAL_TO(_gVersion)                  ( fabsf(NSFoundationVersionNumber - _gVersion) < DBL_EPSILON )
#define SYSTEM_VERSION_GREATER_THAN(_gVersion)              ( NSFoundationVersionNumber >  _gVersion )
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(_gVersion)  ( NSFoundationVersionNumber > _gVersion || SYSTEM_VERSION_EQUAL_TO(_gVersion) )
#define SYSTEM_VERSION_LESS_THAN(_gVersion)                 ( NSFoundationVersionNumber <  _gVersion )
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(_gVersion)     ( NSFoundationVersionNumber < _gVersion || SYSTEM_VERSION_EQUAL_TO(_gVersion)  )


#define PROTEAN_VERSION @"2.0"