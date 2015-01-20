#import <substrate.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "MarqueeLabel.h"
#import <defines.h>
#include <mach/mach_time.h>

#define PADDING   4.0
#define IMAGESIZE 14.0

#define SBHEIGHT (CGFloat)(round([preferences objectForKey: PREFS_HEIGHT_KEY] ? [[preferences objectForKey: PREFS_HEIGHT_KEY] doubleValue] : DEFAULT_HEIGHT))
#define DURATION  [preferences objectForKey: PREFS_DURATION_KEY] ? [[preferences objectForKey: PREFS_DURATION_KEY] doubleValue] : DEFAULT_DURATION
#define SCROLL_SPEED (CGFloat)([preferences objectForKey: PREFS_SPEED_KEY] ? [[preferences objectForKey: PREFS_SPEED_KEY] doubleValue] : DEFAULT_SPEED)
#define ENABLED ([preferences objectForKey: PREFS_ENABLED_KEY] ? [[preferences objectForKey: PREFS_ENABLED_KEY] boolValue] : DEFAULT_ENABLED)
#define BGCOLOR ([preferences objectForKey: PREFS_BACKGROUND_KEY] ? [PRESET_COLORS objectForKey:[preferences objectForKey: PREFS_BACKGROUND_KEY]] : [PRESET_COLORS objectForKey:DEFAULT_BG_COLOR])
#define SHOWTITLE ([preferences objectForKey: PREFS_SHOWTITLE_KEY] ? [[preferences objectForKey: PREFS_SHOWTITLE_KEY] boolValue] : DEFAULT_SHOWTITLE)
#define SHOWICON ([preferences objectForKey: PREFS_SHOWICON_KEY] ? [[preferences objectForKey: PREFS_SHOWICON_KEY] boolValue] : DEFAULT_SHOWICON)
#define SCROLLTOEND ([preferences objectForKey: PREFS_SCROLLTOEND_KEY] ? [[preferences objectForKey: PREFS_SCROLLTOEND_KEY] boolValue] : DEFAULT_SCROLLTOEND)
#define DURATION_LONG (CGFloat)([preferences objectForKey: PREFS_DURATION_LONG_KEY] ? [[preferences objectForKey: PREFS_DURATION_LONG_KEY] doubleValue] : DEFAULT_DURATION_LONG)
#define STRETCH_BANNER ([preferences objectForKey: PREFS_STRETCH_BANNER_KEY] ? [[preferences objectForKey: PREFS_STRETCH_BANNER_KEY] boolValue] : DEFAULT_STRETCH_BANNER)
#define STICKY ([preferences objectForKey: PREFS_STICKY_KEY] ? [[preferences objectForKey: PREFS_STICKY_KEY] boolValue] : DEFAULT_STICKY)
#define DELAY (CGFloat)([preferences objectForKey: PREFS_DELAY_KEY] ? [[preferences objectForKey: PREFS_DELAY_KEY] doubleValue] : DEFAULT_DELAY)
#define FONT [preferences objectForKey: PREFS_FONT_KEY]
#define MESSAGEFONT [preferences objectForKey: PREFS_MESSAGEFONT_KEY]
#define FONTCOLOR [preferences objectForKey:PREFS_FONTCOLOR_KEY]

#define IOS_8_PLUS() [NSClassFromString(@"SBBannerController") instancesRespondToSelector: @selector(_cancelBannerDismissTimers)]

static NSDictionary *preferences = nil;
static CGFloat _dismissInterval = 0;
static CGFloat _replaceInterval = 0;
static BOOL _pulledDown = NO;

// Silence Warnings
@interface NSObject ()
@property (assign,nonatomic) UIEdgeInsets clippingInsets;
@property (copy, nonatomic) NSString *message;
@property (copy, nonatomic) NSString *subtitle;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *sectionID;
@property (copy, nonatomic) id defaultAction;
@property (copy) NSString *secondaryText;
@property(retain, nonatomic) id topAlert; // @synthesize topAlert=_topAlert;

+ (id)action;
+ (id)sharedInstance;
- (void)observer:(id)observer addBulletin:(id)bulletin forFeed:(NSInteger)feed;
- (void)_replaceIntervalElapsed;
- (void)_dismissIntervalElapsed;
- (BOOL)containsAttachments;
- (void)setSecondaryText:(id)text italicized:(BOOL)italicized;
- (int)_ui_resolvedTextAlignment;
- (void)bannerViewControllerDidRequestDismissal:(id)dismissal;

- (UILabel *)tb_titleLabel;
- (MarqueeLabel *)tb_secondaryLabel;
- (void)tb_setTitleLabel:(UILabel *)label;
- (void)tb_setSecondaryLabel:(UILabel *)label;

- (void)tb_createLabelsIfNecessary;
- (NSAttributedString *)tb_addFont:(NSString *)font toString:(NSAttributedString *)string bounds:(CGRect)bounds;
- (UIFont *)scaledFont:(UIFont *)font fromSize:(CGSize)size toRect:(CGRect)bounds;

- (void)_cancelBannerDismissTimers;
- (void)_setUpBannerDismissTimers;

- (BOOL)_isItalicizedAttributedString:(NSAttributedString *)string;
- (NSAttributedString *)_newAttributedStringForSecondaryText:(NSString *)text italicized:(BOOL)italicized;

- (BOOL)isPulledDown;
- (BOOL)showsKeyboard;
- (void)_dismissOverdueOrDequeueIfPossible;
- (void)_dismissBannerWithAnimation:(_Bool)animation reason:(long long)reason forceEvenIfBusy:(_Bool)busy completion:(id)completion;
- (void)_tryToDismissWithAnimation:(_Bool)animation reason:(long long)reason forceEvenIfBusy:(_Bool)busy completion:(id)completion;
- (id)_bannerContext;
@end

@interface UIBackdropView : NSObject
- (id)initWithFrame:(CGRect)frame autosizesToFitSuperview:(BOOL)resizes settings:(id)settings;
+ (id)settingsForStyle:(int)style;
- (void)transitionToStyle:(int)style;
- (void)transitionToColor:(UIColor *)color;
@end

static void reloadPreferences() {
	if (preferences) {
		[preferences release];
		preferences = nil;
	}

	if (IOS_8_PLUS()) {
		// Use CFPreferences since sometimes the prefs dont synchronize to the disk immediately
		NSArray *keyList = [(NSArray *)CFPreferencesCopyKeyList((CFStringRef)APPID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) autorelease];
		preferences = (NSDictionary *)CFPreferencesCopyMultiple((CFArrayRef)keyList, (CFStringRef)APPID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	} else {
		// CFPreferences don't sync immediately but the disk does
		preferences = [[NSDictionary dictionaryWithContentsOfFile: PREFS_PATH] retain];
	}
	if (!preferences || preferences.count == 0) {
		preferences = [DEFAULT_PREFS retain];
	}
}

static BOOL isApplicationBlacklisted(NSString *sectionID) {
	NSNumber *value = [preferences objectForKey: [@"blacklist_" stringByAppendingString: sectionID]];
	if (!value)
		return NO;
	return value.boolValue;
}

static void showTestBanner() {
	id request = [[[NSClassFromString(@"BBBulletinRequest") alloc] init] autorelease];
	[request setTitle: @"BannerStatus"];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad || (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]))) {
		[request setMessage: @"Preferences saved!\nThis is a really really really really really really really really really really really really long test notification to show scrolling."];
	} else {
		[request setMessage: @"Preferences saved! This is an extra long test notification to show scrolling."];
	}
	[request setSectionID: @"com.apple.Preferences"];
	[request setDefaultAction: [NSClassFromString(@"BBAction") action]];

	id ctrl = [NSClassFromString(@"SBBulletinBannerController") sharedInstance];
	[ctrl observer:nil addBulletin:request forFeed:2];
}

