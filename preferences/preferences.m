#import <Preferences/Preferences.h>

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
	UIBarButtonItem *button = [[[UIBarButtonItem alloc] initWithTitle:@"Test" style:UIBarButtonItemStylePlain target:self action:@selector(testBulletin:)] autorelease];
  	self.navigationItem.rightBarButtonItem = button;	
}

- (void)testBulletin:(id)sender {
	NSLog(@"TinyBar: TEST BULLETINS");
}

@end
