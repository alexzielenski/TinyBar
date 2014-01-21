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

}

- (void)resetDefaults:(PSSpecifier *)spec {
	[[NSFileManager defaultManager] removeItemAtURL: [NSURL fileURLWithPath: PREFS_PATH] error: nil];
	[self setPreferenceValue: @DEFAULT_HEIGHT specifier: [self specifierForID: PREFS_HEIGHT_KEY]];
	[self setPreferenceValue: @DEFAULT_SPEED specifier: [self specifierForID: PREFS_SPEED_KEY]];
	[self setPreferenceValue: @DEFAULT_DURATION specifier: [self specifierForID: PREFS_DURATION_KEY]];
	[self setPreferenceValue: @DEFAULT_ENABLED specifier: [self specifierForID: PREFS_ENABLED_KEY]];
	[self setPreferenceValue: @DEFAULT_SHOWTITLE specifier: [self specifierForID: PREFS_SHOWTITLE_KEY]];
	[self setPreferenceValue: @DEFAULT_SCROLLTOEND specifier: [self specifierForID: PREFS_SCROLLTOEND_KEY]];
	[self setPreferenceValue: @DEFAULT_SHOWICON specifier: [self specifierForID: PREFS_SHOWICON_KEY]];
	[self setPreferenceValue: @DEFAULT_DURATION_LONG specifier: [self specifierForID: PREFS_DURATION_LONG_KEY]];
	[self setPreferenceValue: @DEFAULT_STRETCH_BANNER specifier: [self specifierForID: PREFS_STRETCH_BANNER_KEY]];
	[self setPreferenceValue: @DEFAULT_STICKY specifier: [self specifierForID: PREFS_STICKY_KEY]];
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
