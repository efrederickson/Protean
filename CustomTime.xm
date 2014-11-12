#import "Protean.h"

BOOL wasLowercased = NO;

%hook SBStatusBarStateAggregator
- (void)_resetTimeItemFormatter
{
	%orig;

	id enabled_ = [Protean getOrLoadSettings][@"enabled"];
	BOOL enabled = enabled_ ? [enabled_ boolValue] : YES;

	NSDateFormatter *formatter = MSHookIvar<NSDateFormatter*>(self, "_timeItemDateFormatter");

	if (!formatter)
		return;
	
	NSString *format = [Protean getOrLoadSettings][@"timeFormat"];
	if (format && enabled)
		[formatter setDateFormat:format];

	id lowercaseAMPM_ = [Protean getOrLoadSettings][@"lowercaseAMPM"];

	if (lowercaseAMPM_ && [lowercaseAMPM_ boolValue] == YES && enabled)
	{
		[formatter setAMSymbol:@"am"];
		[formatter setPMSymbol:@"pm"];
		wasLowercased = YES;
	}
	else
	{
		if (wasLowercased)
		{
			[formatter setAMSymbol:@"AM"];
			[formatter setPMSymbol:@"PM"];
			wasLowercased = NO;
		}
	}
}
%end

/*
%hook UIStatusBarTimeItemView
- (id)contentsImage
{
	CHECK_ENABLED(%orig);

	id lowercaseAMPM_ = [Protean getOrLoadSettings][@"lowercaseAMPM"];
	if (lowercaseAMPM_ && [lowercaseAMPM_ boolValue] == YES)
	{
		NSString *&time = MSHookIvar<NSString *>(self, "_timeString");
		NSString *time2 = [[time lowercaseString] retain];
		[time release];
		time = time2;
		return %orig;
	}
}
%end
*/

