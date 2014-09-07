#import "Protean.h"

%hook SBStatusBarStateAggregator
- (void)_resetTimeItemFormatter
{
	%orig;

	NSDateFormatter *formatter = MSHookIvar<NSDateFormatter*>(self, "_timeItemDateFormatter");

	NSString *format = [Protean getOrLoadSettings][@"timeFormat"];
	if (format)
		[formatter setDateFormat:format];

	id lowercaseAMPM_ = [Protean getOrLoadSettings][@"lowercaseAMPM"];
	if (lowercaseAMPM_ && [lowercaseAMPM_ boolValue] == YES)
	{
		[formatter setAMSymbol:@"am"];
		[formatter setPMSymbol:@"pm"];
	}
	else
	{
		[formatter setAMSymbol:@"AM"];
		[formatter setPMSymbol:@"PM"];
	}
}
%end