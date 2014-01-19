#import <Preferences/Preferences.h>
#import <defines.h>

@interface TinyBarListController: PSListController
@end


@implementation TinyBarListController

- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"TinyBar" target:self] retain];
	}
	return _specifiers;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// UIBarButtonItem *button = [[[UIBarButtonItem alloc] initWithTitle:@"Test" style:UIBarButtonItemStylePlain target:self action:@selector(testBulletin:)] autorelease];
  	// self.navigationItem.rightBarButtonItem = button;	
}

- (void)testBulletin:(id)sender {
	// SBBannerController *ctrl = [%c(SBBannerController) sharedInstance];
	// SBBulletinBannerController *bulletin = [%c(SBBulletinBannerController) sharedInstance];


	// [ctrl _presentBannerForContext: reason: 1];

	// [[%c(SBBulletinBannerController) sharedInstance] _showTestBanner: @"1"];

}

- (void)resetDefaults:(PSSpecifier *)spec {
	[[NSFileManager defaultManager] removeItemAtURL: [NSURL fileURLWithPath: PREFS_PATH] error: nil];
	[self setPreferenceValue: @DEFAULT_HEIGHT specifier: [self specifierForID: PREFS_HEIGHT_KEY]];
	[self setPreferenceValue: @DEFAULT_SPEED specifier: [self specifierForID: PREFS_SPEED_KEY]];
	[self setPreferenceValue: @DEFAULT_DURATION specifier: [self specifierForID: PREFS_DURATION_KEY]];
	[self setPreferenceValue: @DEFAULT_ENABLED specifier: [self specifierForID: PREFS_ENABLED_KEY]];
	[self reloadSpecifiers];
	
	CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterPostNotification(r, (CFStringRef)@"com.alexzielenski.tinybar/prefsChanged", NULL, NULL, true);
}

- (void)visitWebsite:(id)sender {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.alexzielenski.com"]];
}

- (void)visitTwitter:(id)sender {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/alexzielenski"]];
}

@end
