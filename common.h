#import "headers.h"

#define CHECK_ENABLED(x) \
id _enabled = [Protean getOrLoadSettings][@"enabled"]; \
if ((_enabled ? [_enabled boolValue] : YES) == NO) \
    return x;

#define CHECK_ENABLED2(x) \
id _enabled = [Protean getOrLoadSettings][@"enabled"]; \
if ((_enabled ? [_enabled boolValue] : YES) == NO) \
x; \
return;