#import <Preferences/Preferences.h>
#import <UIKit/UIKit.h>
#import <defines.h>

@interface BannerStatusListController : PSListController
@property (retain) NSArray *families;
@end

@implementation BannerStatusListController

- (id)specifiers {
	if (_specifiers == nil)
		_specifiers = [[self loadSpecifiersFromPlistName:@"BannerStatus" target:self] retain];
	return _specifiers;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	self.families = [@[DEFAULT_FONT] arrayByAddingObjectsFromArray:[[UIFont familyNames] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];

	UIBarButtonItem *button = [[[UIBarButtonItem alloc] initWithTitle:@"Test" style:UIBarButtonItemStylePlain target:self action:@selector(testBulletin:)] autorelease];
	self.navigationItem.rightBarButtonItem = button;
}

- (void)testBulletin:(id)sender {
	CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
	CFNotificationCenterPostNotification(r, (CFStringRef)@"com.iexiled.bannerstatus/prefsChanged", NULL, NULL, true);
}

- (void)resetDefaults:(PSSpecifier *)spec {
	//!TODO: Does not reset blacklist

	[[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:PREFS_PATH] error:nil];
	[self setPreferenceValue:@DEFAULT_HEIGHT specifier:[self specifierForID:PREFS_HEIGHT_KEY]];
	[self setPreferenceValue:@DEFAULT_ENABLED specifier:[self specifierForID:PREFS_ENABLED_KEY]];
	[self setPreferenceValue:@DEFAULT_SHOWTITLE specifier:[self specifierForID:PREFS_SHOWTITLE_KEY]];
	[self setPreferenceValue:@DEFAULT_SCROLLTOEND specifier:[self specifierForID:PREFS_SCROLLTOEND_KEY]];
	[self setPreferenceValue:@DEFAULT_SHOWICON specifier:[self specifierForID:PREFS_SHOWICON_KEY]];
	[self setPreferenceValue:@DEFAULT_STRETCH_BANNER specifier:[self specifierForID:PREFS_STRETCH_BANNER_KEY]];
	[self setPreferenceValue:@DEFAULT_STICKY specifier:[self specifierForID:PREFS_STICKY_KEY]];
	[self setPreferenceValue:DEFAULT_FONT specifier:[self specifierForID:PREFS_FONT_KEY]];
	[self setPreferenceValue:DEFAULT_FONT specifier:[self specifierForID:PREFS_MESSAGEFONT_KEY]];
	[self reloadSpecifiers];

	CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
	CFNotificationCenterPostNotification(r, (CFStringRef)@"com.iexiled.bannerstatus/prefsChanged", NULL, NULL, true);
}

- (NSArray *)fontValues {
	return self.families;
}

- (NSArray *)colorValues:(id)target {
	NSMutableArray *titles = [NSMutableArray arrayWithArray:[[PRESET_COLORS allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
	[titles removeObject:@"Default"];
	[titles insertObject:@"Default" atIndex:0];
	return titles;
}

- (NSString *)fontFamilyForSpecifier:(PSSpecifier *)spec {
	NSUserDefaults *defaults = [[[NSUserDefaults alloc] init] autorelease];
	[defaults addSuiteNamed:[spec propertyForKey:@"defaults"]];
	NSString *fontName = [defaults stringForKey:[spec propertyForKey:@"key"]];
	if (!fontName || [fontName isEqualToString:@"Default"])
		return @"Default";

	UIFont *font = [UIFont fontWithName:fontName size:14.0];
	return font.familyName ?: @"Default";
}

- (void)dealloc {
	self.families = nil;
	[super dealloc];
}

@end

@interface AnimationsListController : PSListController
@end

@implementation AnimationsListController

- (id)specifiers {
	if (_specifiers == nil)
		_specifiers = [[self loadSpecifiersFromPlistName:@"Animations" target:self] retain];
	return _specifiers;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	UIBarButtonItem *button = [[[UIBarButtonItem alloc] initWithTitle:@"Reset" style:UIBarButtonItemStylePlain target:self action:@selector(resetDefaults:)] autorelease];
	self.navigationItem.rightBarButtonItem = button;
}

- (void)resetDefaults:(PSSpecifier *)spec {
	//!TODO: Does not reset blacklist

	[[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:PREFS_PATH] error:nil];
	[self setPreferenceValue:@DEFAULT_SPEED specifier:[self specifierForID:PREFS_SPEED_KEY]];
	[self setPreferenceValue:@DEFAULT_DURATION specifier:[self specifierForID:PREFS_DURATION_KEY]];
	[self setPreferenceValue:@DEFAULT_STRETCH_BANNER specifier:[self specifierForID:PREFS_STRETCH_BANNER_KEY]];
	[self setPreferenceValue:@DEFAULT_DELAY specifier:[self specifierForID:PREFS_DELAY_KEY]];
	[self reloadSpecifiers];

	CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
	CFNotificationCenterPostNotification(r, (CFStringRef)@"com.iexiled.bannerstatus/prefsChanged", NULL, NULL, true);
}

@end

@interface CreditsListController : PSListController
@end

@implementation CreditsListController

- (id)specifiers {
	if (_specifiers == nil)
		_specifiers = [[self loadSpecifiersFromPlistName:@"Credits" target:self] retain];
	return _specifiers;
}

- (void)visitWebsite:(id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[(PSSpecifier *)sender propertyForKey:@"website"]]];
}

- (void)visitTwitter:(id)sender {
	NSString *user = [(PSSpecifier *)sender propertyForKey:@"userName"];

	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]])
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tweetbot:///user_profile/%@", user]]];
	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]])
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitter://user?screen_name=%@", user]]];
	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]])
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitterrific:///profile?screen_name=%@", user]]];
	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]])
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tweetings:///user?screen_name=%@", user]]];
	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]])
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitter://user?screen_name=%@", user]]];
	else
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://mobile.twitter.com/%@", user]]];
}

@end

//@interface ContactCell : PSTableCell {
//	UILabel *_screenName;
//	UIImageView *_profileImage;
//}
//- (void)connectToTwitter;
//@end
//
//@implementation ContactCell
//
//<#methods#>
//
//@end

@interface BSFontNameListController : UITableViewController
@property (retain) NSArray *fontNames;
@property (retain) PSSpecifier *specifier;
@end

@interface BSFontListController : PSListItemsController
@property (retain) BSFontNameListController *nameListController;
@end

@implementation BSFontListController

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *font = [[[tableView cellForRowAtIndexPath:indexPath] textLabel] text];
	if ([font isEqualToString:@"Default"]) {
		SEL setter = self.specifier->setter;
		id target = self.specifier->target;

		[target performSelector:setter withObject:font withObject:self.specifier];
		[target reloadSpecifier:self.specifier animated:YES];
		[self.navigationController popToViewController:target animated:YES];
		return;
	}

	if (!self.nameListController)
		self.nameListController = [[[BSFontNameListController alloc] initWithNibName:nil bundle:nil] autorelease];

	self.nameListController.title = font;
	self.nameListController.fontNames = [UIFont fontNamesForFamilyName:font];
	self.nameListController.specifier = [self specifier];
	[self.nameListController.tableView reloadData];
	[self.navigationController pushViewController:self.nameListController animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell *cell = [super tableView:table cellForRowAtIndexPath:indexPath];
	cell.textLabel.font = [UIFont fontWithName:cell.textLabel.text size:cell.textLabel.font.pointSize];

	if (indexPath.row)
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

@end

@implementation BSFontNameListController

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.fontNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FontName"];

	if (!cell)
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FontName"] autorelease];

	cell.textLabel.text = [self.fontNames objectAtIndex:indexPath.row];
	cell.textLabel.font = [UIFont fontWithName:cell.textLabel.text size:cell.textLabel.font.pointSize];

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	NSString *fontName = cell.textLabel.text;

	SEL setter = self.specifier->setter;
	id target = self.specifier->target;

	[target performSelector:setter withObject:fontName withObject:self.specifier];
	[target reloadSpecifier:self.specifier animated:YES];
	[self.navigationController popToViewController:target animated:YES];
}

- (void)dealloc {
	self.fontNames = nil;
	self.specifier = nil;
	[super dealloc];
}

@end
