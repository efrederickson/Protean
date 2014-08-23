#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <SettingsKit/SKStandardController.h>
#import <SettingsKit/SKPersonCell.h>
#import <SettingsKit/SKSharedHelper.h>

@interface PRMakersListController : SKTintedListController<SKListControllerProtocol>
@end
@interface PRElijahPersonCell : SKPersonCell
@end
@interface PRAndrewPersonCell : SKPersonCell
@end

@implementation PRElijahPersonCell
-(NSString*)personDescription { return @"The Developer"; }
-(NSString*)name { return @"Elijah Frederickson"; }
-(NSString*)imageName { return @"elijah.png"; }
@end

@implementation PRAndrewPersonCell
-(NSString*)personDescription { return @"The Designer"; }
-(NSString*)name { return @"Andrew Abosh"; }
-(NSString*)imageName { return @"andrew.png"; }
@end

@implementation PRMakersListController
//-(UIColor*) navigationTintColor { return [UIColor colorWithRed:11/255.0f green:234/255.0f blue:241/255.0f alpha:1.0f]; }
-(BOOL) showHeartImage { return NO; }
-(NSString*) customTitle { return @"Credits"; }

- (id)customSpecifiers {
    return @[
             @{ @"cell": @"PSGroupCell" },
             @{
                 @"cell": @"PSLinkCell",
                 @"cellClass": @"PRElijahPersonCell",
                 @"height": @100,
                 @"action": @"openElijahTwitter"
                 },
             @{ @"cell": @"PSGroupCell" },
             @{
                 @"cell": @"PSLinkCell",
                 @"cellClass": @"PRAndrewPersonCell",
                 @"height": @100,
                 @"action": @"openAndrewTwitter"
                 },
             @{ @"cell": @"PSGroupCell" },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Source Code",
                 @"action": @"openGithub",
                 @"icon": @"github.png"
                 },
             
             
             @{ @"cell": @"PSGroupCell",
                @"label": @"Recommended Themes" },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"OpenNotifier iOS7 IconPack",
                 @"action": @"openRCRepoPack",
                 @"icon": @"rcrepopack.png"
                 },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Habesha OpenNotifier Icons",
                 @"action": @"openHabeshaPack",
                 @"icon": @"rhabeshapack.png"
                 },
             
             @{ @"cell": @"PSGroupCell",
                @"label": @"Recommended StatusBar Tweaks" },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Circlet (by @insanj)",
                 @"action": @"openCirclet",
                 @"icon": @"circlet.png"
                 },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"NowPlayingIndicator",
                 @"action": @"openNowPlaying",
                 @"icon": @"circlet.png"
                 },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Alkaline",
                 @"action": @"openAlkaline",
                 @"icon": @"alkaline.png"
                 },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Zeppelin",
                 @"action": @"openZeppelin",
                 @"icon": @"zeppelin.png"
                 },
             
             @{ @"cell": @"PSGroupCell",
                @"footerText": @"Acknowledgments: \n\
\n\
Julian Weiss - StatusBar refresh animation\n\
Bensge - UIStatusBar research\n\
n00neimp0rtant & tateu - OpenNotifier\n\n\
Situ Herrera, Pele Saeng-a-loon Chaengsavang, Icons8, Allan McAvoy, and Alessio Atzeni - Provided some glyphs and inspiration.\n\n\
All of you for the tremendous support.\n\
\n\
\n\
Beta testers:\n\
CPDigitalDarkroom\n\
hellomisterjedi\n\
hodhr\n\
/u/narcolepticinsomniac\n\
/u/binders_of_women_",
                },
             ];
}

-(void) openZeppelin
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://package/com.alexzielenski.zeppelin"]];
}

-(void) openAlkaline
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://package/com.fortysixandtwo.alkaline"]];
}

-(void) openRCRepoPack
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"3rd Party Source" message:@"This icon pack is from the Reddit community repo!\nMake sure you have rcrepo.com added as a Cydia source!" delegate:self cancelButtonTitle:@"Have it" otherButtonTitles:nil];
    [alert addButtonWithTitle:@"Add Repo"];
    [alert setTag:3];
    [alert show];
}

-(void) openHabeshaPack
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"3rd Party Package" message:@"This icon pack is from the DeviantArt.\nYou will need to download & install following the instructions on that page." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert setTag:33];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 3)
    {
        if (buttonIndex == 1)
        {
            [[UIPasteboard generalPasteboard] setString:@"rcrepo.com"];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"RCRepo.com" message:@"The source link has been copied to the clipboard.\nPaste it into Cydia's \"Add Sources\" Dialog." delegate:self cancelButtonTitle:@"Launch Cydia" otherButtonTitles:nil];
            [alert setTag:34];
            [alert show];
        }
        else
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://package/com.md.on7"]];
    }
    else if (alertView.tag == 33)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://nienque.deviantart.com/art/iOS7-OpenNotifier-icons-for-Habesha-440794317"]];
    }
    else if (alertView.tag == 34)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://sources"]];
    }
}

-(void) openCirclet
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://package/com.insanj.circlet"]];
}

-(void) openNowPlaying
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://package/de.schwalzik-marvin.nowplayingstat"]];
}

-(void) openGithub
{
    [SKSharedHelper openGitHub:@"mlnlover11/Protean"];
}

-(void) openElijahTwitter
{
    [SKSharedHelper openTwitter:@"daementor"];
}

-(void) openAndrewTwitter
{
    [SKSharedHelper openTwitter:@"drewplex"];
}
@end
