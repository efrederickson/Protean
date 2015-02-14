#import "PRStatusApps.h"
#import "common.h"

static BBServer *sharedServer;
%hook BBServer
%new +(id) PR_sharedInstance
{
	return sharedServer;
}

-(id) init
{
	sharedServer = %orig;
	return sharedServer;
}

- (void)publishBulletin:(BBBulletin*)arg1 destinations:(unsigned long long)arg2 alwaysToLockScreen:(_Bool)arg3
{
    %orig;

	NSArray *bulletins = [self allBulletinIDsForSectionID:arg1.sectionID];
	int count = bulletins.count;
    [%c(PRStatusApps) updateNCStatsForIcon:[arg1.sectionID copy] count:count]; // Update stats for Notification center icons
}

- (void)_sendRemoveBulletins:(NSSet*)arg1 toFeeds:(unsigned long long)arg2 shouldSync:(_Bool)arg3
{
    %orig;

    BBBulletin *bulletin = [arg1 anyObject];
    if (!bulletin)
        return;

    NSString *section = bulletin.sectionID;
	[%c(PRStatusApps) updateNCStatsForIcon:section count:[%c(PRStatusApps) ncCount:section] - arg1.count];
}
%end