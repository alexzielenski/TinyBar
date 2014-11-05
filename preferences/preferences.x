#import <Preferences/Preferences.h>
#import <defines.h>

@interface TinyBarListController: PSListController
@property (retain) NSArray *families;
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

	self.families = [@[DEFAULT_FONT] arrayByAddingObjectsFromArray: [[UIFont familyNames] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]];

	UIBarButtonItem *button = [[[UIBarButtonItem alloc] initWithTitle:@"Test" style:UIBarButtonItemStylePlain target:self action:@selector(testBulletin:)] autorelease];
  	self.navigationItem.rightBarButtonItem = button;	
}

- (void)testBulletin:(id)sender {
	CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
	CFNotificationCenterPostNotification(r, (CFStringRef)@"com.alexzielenski.tinybar/prefsChanged", NULL, NULL, true);
}

- (void)resetDefaults:(PSSpecifier *)spec {
//!TODO: Does not reset blacklist

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
	[self setPreferenceValue: @DEFAULT_DELAY specifier: [self specifierForID: PREFS_DELAY_KEY]];
	[self setPreferenceValue: DEFAULT_FONT specifier: [self specifierForID: PREFS_FONT_KEY]];
	[self setPreferenceValue: DEFAULT_FONT specifier: [self specifierForID: PREFS_MESSAGEFONT_KEY]];
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

- (NSArray *)fontValues {
	return self.families;
}

- (NSString *)fontFamilyForSpecifier:(PSSpecifier *)spec {
	NSUserDefaults *defaults = [[[NSUserDefaults alloc] init] autorelease];
	[defaults addSuiteNamed:[spec propertyForKey: @"defaults"]];
	NSString *fontName = [defaults stringForKey: [spec propertyForKey: @"key"]];
	if (!fontName || [fontName isEqualToString: @"Default"])
		return @"Default";
	
	UIFont *font = [UIFont fontWithName: fontName size:14.0];
	return font.familyName ?: @"Default";
}

- (void)dealloc {
	self.families = nil;
	[super dealloc];
}

@end

@interface TBFontNameListController : UITableViewController
@property (retain) NSArray *fontNames;
@property (retain) PSSpecifier *specifier;
@end

@interface TBFontListController : PSListItemsController
@property (retain) TBFontNameListController *nameListController;
@end

@implementation TBFontListController

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *font = [[[tableView cellForRowAtIndexPath: indexPath] textLabel] text];
	if ([font isEqualToString: @"Default"]) {
		SEL setter = self.specifier->setter;
		id target = self.specifier->target;

		[target performSelector: setter withObject:font withObject:self.specifier];
		[target reloadSpecifier: self.specifier animated: YES];
		[self.navigationController popToViewController:target animated: YES];
		return;
	}

	if (!self.nameListController) {
		self.nameListController = [[[TBFontNameListController alloc] initWithNibName: nil bundle: nil] autorelease];
	}
	self.nameListController.title = font;
	self.nameListController.fontNames = [UIFont fontNamesForFamilyName: font];
	self.nameListController.specifier = [self specifier];
	[self.nameListController.tableView reloadData];
	[self.navigationController pushViewController: self.nameListController animated: YES];
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)arg2 {

	UITableViewCell *cell = [super tableView:table cellForRowAtIndexPath: arg2];
	cell.textLabel.font = [UIFont fontWithName: cell.textLabel.text size: cell.textLabel.font.pointSize];

	if (arg2.row)
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

@end

@implementation TBFontNameListController

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.fontNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FontName"];

    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FontName"] autorelease];
    }

    cell.textLabel.text = [self.fontNames objectAtIndex: indexPath.row];
    cell.textLabel.font = [UIFont fontWithName: cell.textLabel.text size: cell.textLabel.font.pointSize];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];
	NSString *fontName = cell.textLabel.text;

	SEL setter = self.specifier->setter;
	id target = self.specifier->target;

	[target performSelector:setter withObject:fontName withObject:self.specifier];
	[target reloadSpecifier: self.specifier animated: YES];
	[self.navigationController popToViewController:target animated: YES];
}

- (void)dealloc {
	self.fontNames = nil;
	self.specifier = nil;
	[super dealloc];
}

@end
