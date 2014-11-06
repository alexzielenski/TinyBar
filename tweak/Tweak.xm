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
#define SHOWTITLE ([preferences objectForKey: PREFS_SHOWTITLE_KEY] ? [[preferences objectForKey: PREFS_SHOWTITLE_KEY] boolValue] : DEFAULT_SHOWTITLE)
#define SHOWICON ([preferences objectForKey: PREFS_SHOWICON_KEY] ? [[preferences objectForKey: PREFS_SHOWICON_KEY] boolValue] : DEFAULT_SHOWICON)
#define SCROLLTOEND ([preferences objectForKey: PREFS_SCROLLTOEND_KEY] ? [[preferences objectForKey: PREFS_SCROLLTOEND_KEY] boolValue] : DEFAULT_SCROLLTOEND)
#define DURATION_LONG (CGFloat)([preferences objectForKey: PREFS_DURATION_LONG_KEY] ? [[preferences objectForKey: PREFS_DURATION_LONG_KEY] doubleValue] : DEFAULT_DURATION_LONG)
#define STRETCH_BANNER ([preferences objectForKey: PREFS_STRETCH_BANNER_KEY] ? [[preferences objectForKey: PREFS_STRETCH_BANNER_KEY] boolValue] : DEFAULT_STRETCH_BANNER)
#define STICKY ([preferences objectForKey: PREFS_STICKY_KEY] ? [[preferences objectForKey: PREFS_STICKY_KEY] boolValue] : DEFAULT_STICKY)
#define DELAY (CGFloat)([preferences objectForKey: PREFS_DELAY_KEY] ? [[preferences objectForKey: PREFS_DELAY_KEY] doubleValue] : DEFAULT_DELAY)
#define FONT [preferences objectForKey: PREFS_FONT_KEY]
#define MESSAGEFONT [preferences objectForKey: PREFS_MESSAGEFONT_KEY]

#define IS_IOS_8_PLUS() [%c(SBBannerController) instancesRespondToSelector: @selector(_cancelBannerDismissTimers)]

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
- (void)observer:(id)arg1 addBulletin:(id)arg2 forFeed:(NSInteger)arg3;
- (void)_replaceIntervalElapsed;
- (void)_dismissIntervalElapsed;
- (BOOL)containsAttachments;
- (void)setSecondaryText:(id)arg1 italicized:(BOOL)arg2;
- (int)_ui_resolvedTextAlignment;
- (void)bannerViewControllerDidRequestDismissal:(id)arg1;

- (UILabel *)tb_titleLabel;
- (MarqueeLabel *)tb_secondaryLabel;
- (void)tb_setTitleLabel:(UILabel *)label;
- (void)tb_setSecondaryLabel:(UILabel *)label;

- (void)tb_createLabelsIfNecessary;
- (NSAttributedString *)tb_addFont:(NSString *)font toString:(NSAttributedString *)string bounds:(CGRect)bounds;
- (UIFont *)scaledFont:(UIFont *)font fromSize:(CGSize)size toRect:(CGRect)bounds;

- (void)_cancelBannerDismissTimers;
- (void)_setUpBannerDismissTimers;

- (BOOL)_isItalicizedAttributedString:(NSAttributedString *)arg1;
- (NSAttributedString *)_newAttributedStringForSecondaryText:(NSString *)arg1 italicized:(BOOL)arg2;

- (BOOL)isPulledDown;
- (BOOL)showsKeyboard;
- (void)_dismissOverdueOrDequeueIfPossible;
- (void)_dismissBannerWithAnimation:(_Bool)arg1 reason:(long long)arg2 forceEvenIfBusy:(_Bool)arg3 completion:(id)arg4;
- (void)_tryToDismissWithAnimation:(_Bool)arg1 reason:(long long)arg2 forceEvenIfBusy:(_Bool)arg3 completion:(id)arg4;
- (id)_bannerContext;
@end

static void reloadPreferences() {
	if (preferences) {
		[preferences release];
		preferences = nil;
	}
	
	if (IS_IOS_8_PLUS()) {
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
	id request = [[[%c(BBBulletinRequest) alloc] init] autorelease];
	[request setTitle: @"TinyBar"];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad || (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]))) {
	 	[request setMessage: @"Preferences saved!\nThis is a really really really really really really really really really really really really long test notification to show scrolling."];
	 } else {
	 	[request setMessage: @"Preferences saved! This is an extra long test notification to show scrolling."];
	}
	[request setSectionID: @"com.apple.Preferences"];
	[request setDefaultAction: [%c(BBAction) action]];
	
	id ctrl = [%c(SBBulletinBannerController) sharedInstance];
	[ctrl observer:nil addBulletin:request forFeed:2];
}

%hook SBDefaultBannerView

- (void)layoutSubviews {
	%orig;
	
	UIImageView *attachment = MSHookIvar<UIImageView *>(self, "_attachmentImageView");
	UIView *textView = MSHookIvar<UIView *>(self, "_textView");
	UIView *imageView = MSHookIvar<UIView *>(self, "_iconImageView");
	UIView *grabberView = nil;
	UIView *secondaryContentView = nil;

	// The grabber view was removed in iOS 8
	Ivar grabberVar = class_getInstanceVariable([self class], "_grabberView");
	if (grabberVar != NULL) {
		grabberView = object_getIvar(self, grabberVar);
	}
	
	Ivar secondaryContentVar = class_getInstanceVariable([self class], "_secondaryContentView");
	if (secondaryContentVar != NULL) {
		secondaryContentView = object_getIvar(self, secondaryContentVar);
	}
	

	if (!ENABLED || _pulledDown) {
		secondaryContentView.alpha = 1.0;
		attachment.alpha = 1.0;
		imageView.alpha = 1.0;
		grabberView.alpha = 1.0;
		return;
	}
	
	secondaryContentView.alpha = 0.0;

	// Hide the grabber
	grabberView.alpha = 0.0;
	
	// Get rid of the attachment
	attachment.alpha = 0.0;

	CGRect bounds = [(UIView *)self bounds];

	// Make the image our size and vertically center it
	CGRect imageFrame = CGRectZero;
	
	if (SHOWICON) {
		imageFrame.origin.y = floor(bounds.size.height / 2 - IMAGESIZE / 2);
		imageFrame.origin.x = 0;
		imageFrame.size.height = IMAGESIZE;
		imageFrame.size.width = IMAGESIZE;
		[imageView setFrame: imageFrame];
		imageView.alpha = 1.0;
	} else {
		imageView.alpha = 0.0;
	}

	// Place the content view PADDING distance away from the image view
	// and make it fill the rest of the view
	CGRect textFrame = textView.frame;
	textFrame.size.height = bounds.size.height;
	textFrame.origin.x = imageFrame.origin.x + imageFrame.size.width;
	
	if (SHOWICON)
		textFrame.origin.x += PADDING;
		
	textFrame.origin.y = 0;
	textFrame.size.width = bounds.size.width - textFrame.origin.x;
	[textView setFrame: textFrame];
}

%end

%hook SBBannerController

- (CGRect)_bannerFrameForOrientation:(NSInteger)arg1 {
	_pulledDown = NO;
	
	id bulletin = [self valueForKeyPath: @"_bannerView.bannerContext.item.seedBulletin"];
	if (isApplicationBlacklisted([bulletin sectionID])) {
		// TLog(@"blacklisted");
		_pulledDown = YES;
	}
	
	CGRect o = %orig(arg1);
	if (!ENABLED || _pulledDown)
		return o;

	if (o.size.width == 0 || o.size.height == 0)
		return o;

	// Make the banner window the height of the statusbar
	o.size.height = SBHEIGHT;
	return o;
}

// - (void)_setupBannerDismissTimers {
//     %log;
//     %orig;
// }
// 
// - (void)_cancelBannerDismissTimers {
//     %log;
//     %orig;
// }

- (void)performSelector:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay inModes:(NSArray *)modes {
	// %log;
	   
    NSString *sel = NSStringFromSelector(aSelector);
    if (ENABLED && !_pulledDown) {
		if ([sel isEqualToString: @"_replaceIntervalElapsed"]) {
			delay = _replaceInterval;
		} else if ([sel isEqualToString: @"_dismissIntervalElapsed"]) {
			if (STICKY)
				return;
			delay = _dismissInterval;
		}
		
    }
	%orig(aSelector, anArgument, delay, modes);
}
// 
// - (void)_replaceIntervalElapsed {
//     %log;
//     %orig;
// }
// 
// - (void)_dismissIntervalElapsed {
//     %log;
//     %orig;
// }

%end

%hook SBBannerContainerViewController

- (CGRect)_bannerFrameForOrientation:(NSInteger)arg1 {
	// %log;
	_pulledDown = NO;
	
	id bulletin = [self valueForKeyPath: @"_bannerContext.item.seedBulletin"];
	if (isApplicationBlacklisted([bulletin sectionID]) || [self isPulledDown]) {
		TLog(@"blacklisted");
		_pulledDown = YES;
	}

	CGRect o = %orig(arg1);
	if (!ENABLED || _pulledDown)
		return o;
	
	if (o.size.width == 0 || o.size.height == 0)
		return o;
	
	// Make the banner window the height of the statusbar
	o.size.height = SBHEIGHT;
	return o;
}

- (void)setBannerPullPercentage:(CGFloat)arg1 {
	//Disable tinybar
	// %log;
	if (arg1 > 0.45)
		_pulledDown = YES;
	%orig(arg1);
}

%end

%hook SBBannerContextView

- (void)setClippingInsets:(UIEdgeInsets)arg1 {
	if (ENABLED && !_pulledDown)
		%orig(UIEdgeInsetsZero);
	else
		%orig(arg1);
}

- (CGRect)_contentFrame {
	// For iPad: make the notification banners the entire width of the screen
	// rather than having them be tiny
	CGRect o = %orig;
	if (!ENABLED || !STRETCH_BANNER || _pulledDown)
		return o;

	if (o.size.width == 0 || o.size.height == 0)
		return o;

	return CGRectInset([(UIView *)self bounds], PADDING, 0);
}

// iOS 8+ to add padding
- (CGRect)_centeredBounds {
    CGRect o = %orig;
    if (!ENABLED || !STRETCH_BANNER || _pulledDown)
        return o;
    
    if (o.size.width == 0 || o.size.height == 0)
        return o;
    
    CGRect bounds = [(UIView *)self bounds];
    bounds.origin.x += PADDING;
    bounds.size.width -= PADDING * 2;
    
    return bounds;
}

- (CGFloat)_grabberAlpha {
	return ENABLED && !_pulledDown ? 0.0 : %orig;
}

- (CGFloat)minimumHeight {
	return ENABLED && !_pulledDown ? SBHEIGHT : %orig;
}

%end

%hook SBDefaultBannerTextView

%new
- (void)tb_createLabelsIfNecessary {
	UILabel *primary = [self tb_titleLabel];
	if (!primary) {
		primary = [[[UILabel alloc] initWithFrame: CGRectMake(0, 0, 20, ((UIView *)self).bounds.size.height)] autorelease];
		[self tb_setTitleLabel: primary];
	}

	// Create and cache the secondary text label
	MarqueeLabel *secondary = [self tb_secondaryLabel];
	
	if (!secondary) {
		secondary = [[[MarqueeLabel alloc] initWithFrame: CGRectMake(0, 0, 1024, ((UIView *)self).bounds.size.height) rate:SCROLL_SPEED andFadeLength:PADDING] autorelease];
		[secondary setContinuousMarqueeExtraBuffer: 14.0];
		[secondary setAnimationCurve: UIViewAnimationOptionCurveLinear];
		// loop scrolling
		[secondary setMarqueeType: MLContinuous];
		[self tb_setSecondaryLabel: secondary];
	}
}

%new
- (NSAttributedString *)tb_addFont:(NSString *)fontName toString:(NSAttributedString *)string bounds:(CGRect)bounds {
	if (fontName && fontName.length && ![fontName isEqualToString: DEFAULT_FONT] && string) {
		NSMutableAttributedString *mut = [string.mutableCopy autorelease];
		UIFont *font = [UIFont fontWithName: fontName size: 14.0];
		[mut addAttribute: NSFontAttributeName value:font range: NSMakeRange(0, mut.length)];
		
		UIFont *newFont = [self scaledFont: font fromSize: mut.size toRect: bounds];
		[mut addAttribute: NSFontAttributeName value:newFont range: NSMakeRange(0, mut.length)];
		return mut;
	}
	
	return string;
}

%new
- (UIFont *)scaledFont:(UIFont *)font fromSize:(CGSize)size toRect:(CGRect)bounds {
	CGFloat factor = (bounds.size.height - PADDING) / size.height;
	
	return [font fontWithSize: font.pointSize * factor];
}

- (void)layoutSubviews {
	// %log;
	%orig;
	
	// Remove date label on iOS7.1+
	Ivar labelVar = class_getInstanceVariable([self class], "_relevanceDateLabel");
	if (labelVar != NULL) {
		UILabel *dateLabel = object_getIvar(self, labelVar);
		if (dateLabel && [dateLabel isKindOfClass: %c(UILabel)]) {
			
			if (!ENABLED || _pulledDown)
				[dateLabel setAlpha: 1.0];
			else
				[dateLabel setAlpha: 0.0];

			// [dateLabel removeFromSuperview];
		}
	}
	CGRect bounds = [(UIView *)self bounds];


	// Create and cache a primary text label
	[self tb_createLabelsIfNecessary];
	UILabel *primary = [self tb_titleLabel];
	
	// Create and cache the secondary text label
	MarqueeLabel *secondary = [self tb_secondaryLabel];
	
	secondary.rate = SCROLL_SPEED;
	secondary.animationDelay = DELAY;
	if (!ENABLED || _pulledDown) {
		[primary removeFromSuperview];
		[secondary removeFromSuperview];
		return;
	}

	// get our strings from ivars
	NSAttributedString *primaryString = MSHookIvar<NSAttributedString *>(self, "_primaryTextAttributedStringComponent");
	NSAttributedString *secondaryAtr = MSHookIvar<NSAttributedString *>(self, "_secondaryTextAttributedString");
	NSAttributedString *secondaryString = nil;
	NSString *secondaryText = [[self secondaryText] stringByReplacingOccurrencesOfString: @"\n" withString: @" "];
	
	if ((!secondaryText || secondaryText.length == 0) && IS_IOS_8_PLUS()) {
		secondaryAtr = MSHookIvar<NSAttributedString *>(self, "_alternateSecondaryTextAttributedString");
		secondaryText = [secondaryAtr.string ?: @"" stringByReplacingOccurrencesOfString: @"\n" withString: @" "];
	}
	
	if (IS_IOS_8_PLUS() && secondaryText) {
		secondaryString = [[self _newAttributedStringForSecondaryText: secondaryText
														 italicized: [self _isItalicizedAttributedString: secondaryAtr]] autorelease];
	} else if (secondaryText) {
		secondaryString = [[[NSAttributedString alloc] initWithString: secondaryText attributes: [secondaryAtr attributesAtIndex: 0 effectiveRange: nil]] autorelease];
	}
	
	if (!primaryString)
		primaryString = [[NSAttributedString alloc] initWithString:@"" attributes: @{}];
	if (!secondaryString)
		secondaryString = [[NSAttributedString alloc] initWithString:@"" attributes: @{}];
	
	// Format Fonts
	primaryString = [self tb_addFont: FONT toString: primaryString bounds: bounds];
	secondaryString = [self tb_addFont: MESSAGEFONT toString: secondaryString bounds: bounds];

	NSString *strRep = secondaryString.string;
	NSString *isoLangCode = [(NSString *)CFStringTokenizerCopyBestStringLanguage((CFStringRef)strRep, CFRangeMake(0, strRep.length)) autorelease];
	NSLocaleLanguageDirection direction = (NSLocaleLanguageDirection)[%c(NSLocale) characterDirectionForLanguage:isoLangCode];

	BOOL rtl = (direction == NSLocaleLanguageDirectionRightToLeft);
	
	[primary setAttributedText: primaryString];
	[secondary setTextAlignment: (rtl) ? NSTextAlignmentRight : NSTextAlignmentLeft];
	[secondary setAttributedText: secondaryString];
	
	if (rtl) {
		[secondary setMarqueeType: MLContinuousReverse];
	} else {
		[secondary setMarqueeType: MLContinuous];
	}

	// find the sizes of our text
	CGRect primaryRect   = CGRectMake(0, 0, primaryString.size.width, primaryString.size.height);
	CGRect secondaryRect = CGRectMake(0, 0, secondaryString.size.width, secondaryString.size.height);

	//! Calculate vertical position of title baseline
	// Center primary text
	// baseline = primaryBase + primary.font.ascender
	// secondaryBase = baseline - secondary.font.ascender
	CGFloat primaryBase = bounds.size.height / 2 - primaryRect.size.height / 2;
	// Align the secondary text baseline to the primary
	CGFloat secondaryBase = primaryBase + (primary.font.ascender - secondary.font.ascender);

	primaryRect.origin.y = primaryBase;
	secondaryRect.origin.y = secondaryBase;

	// Move the title to the right side of we are reading right-to-left
	if (rtl) {
		secondaryRect.origin.x = 0;
		primaryRect.origin.x = bounds.size.width + bounds.origin.x - primaryRect.size.width;
	}

	if (!SHOWTITLE) {
		primaryRect.size.width = 0;
		[primary removeFromSuperview];
	} else {
		[primary setFrame: primaryRect];
		[self addSubview: primary];
	}

	// make the secondary text fille the rest of the view and vertically center it
	if (!rtl)
		secondaryRect.origin.x   += primaryRect.size.width + PADDING;
	secondaryRect.size.width  = bounds.size.width - primaryRect.size.width - PADDING;
	[secondary setFrame: secondaryRect];
	[self addSubview: secondary];
	
	secondary.fadeLength = PADDING;
	if (secondary.animationDuration == 0) {
		secondary.fadeLength = 0.0;
	}
	
	//	Make the banner persist at least as long as the user says or enough for one scroll around
	CGFloat animationDuration = secondary.animationDuration * 2 + secondary.animationDelay;
	CGFloat dismissDuration = secondary.animationDuration > 0.0 ? DURATION_LONG : DURATION;
	CGFloat replaceDuration = (dismissDuration / DEFAULT_DURATION) * 2.375;
	
	if (animationDuration > replaceDuration && SCROLLTOEND && animationDuration > secondary.animationDelay) {
		replaceDuration = animationDuration;
		
		if (animationDuration > DURATION_LONG) {
			dismissDuration = animationDuration;
		}
	}
		
	_dismissInterval = dismissDuration;
	_replaceInterval = replaceDuration;

	if (!IS_IOS_8_PLUS()) {
		// The dismiss scheduling is run after this method is called
		// so it always uses intervals from the previous banner. Cancel/Reapply them
		id bctrl = [%c(SBBannerController) sharedInstance];
		[NSObject cancelPreviousPerformRequestsWithTarget:bctrl selector:@selector(_replaceIntervalElapsed) object: nil];
		[NSObject cancelPreviousPerformRequestsWithTarget:bctrl selector:@selector(_dismissIntervalElapsed) object: nil];
		
		[bctrl performSelector: @selector(_replaceIntervalElapsed) withObject: nil afterDelay: _replaceInterval];
		[bctrl performSelector: @selector(_dismissIntervalElapsed) withObject: nil afterDelay: _dismissInterval];
	}
}

- (void)drawRect:(CGRect)arg1 {
	// overriding so it does nothing
	if (!ENABLED || _pulledDown)
		%orig(arg1);
}

%new
- (UILabel *)tb_titleLabel {
	return objc_getAssociatedObject(self, @selector(tb_titleLabel));
}

%new
- (MarqueeLabel *)tb_secondaryLabel {
	return objc_getAssociatedObject(self, @selector(tb_secondaryLabel));
}

%new
- (void)tb_setTitleLabel:(UILabel *)label {
	objc_setAssociatedObject(self, @selector(tb_titleLabel), label, OBJC_ASSOCIATION_RETAIN);
}

%new
- (void)tb_setSecondaryLabel:(MarqueeLabel *)label {
	// NSAssert([label isKindOfClass: %c(MarqueeLabel)], @"tb_setSecondaryLabel: only takes labels of type: MarqueeLabel");

	objc_setAssociatedObject(self, @selector(tb_secondaryLabel), label, OBJC_ASSOCIATION_RETAIN);
}

- (void)dealloc {
	[self tb_setTitleLabel: nil];
	[self tb_setSecondaryLabel: nil];
	%orig;
}

%end


static inline void prefsChanged(CFNotificationCenterRef center,
									void *observer,
									CFStringRef name,
									const void *object,
									CFDictionaryRef userInfo) {

	TLog(@"Preferences changed!");
	reloadPreferences();

	id bctrl = [%c(SBBannerController) sharedInstance];
	// id ctrl = [%c(SBBulletinBannerController) sharedInstance];

	[NSObject cancelPreviousPerformRequestsWithTarget:bctrl selector:@selector(_replaceIntervalElapsed) object:nil];
	[NSObject cancelPreviousPerformRequestsWithTarget:bctrl selector:@selector(_dismissIntervalElapsed) object:nil];

    // Hide previous banner
 	if (IS_IOS_8_PLUS()) {
 		if (![bctrl _bannerContext]) {
 			[bctrl _replaceIntervalElapsed];	
 			[bctrl _dismissIntervalElapsed];	
	 		showTestBanner();
 		} else {
 			[bctrl _replaceIntervalElapsed];
 			[bctrl _dismissIntervalElapsed];
 			//! This is the hackiest thing i've seen in my life
 			// We need to wait for the bannerContext to go away
 			// before we add another banner. I tried messing with
 			// completion blocks of the banner controller which 
 			// resulted in crashes after rapidly showing test banners
 			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
 				// time out after 2 seconds
 				uint64_t start = mach_absolute_time();
 				mach_timebase_info_data_t info;
 				mach_timebase_info(&info);
				while([bctrl _bannerContext] && (CGFloat)(mach_absolute_time() - start) * info.numer / info.denom / pow(10, 9) < 2.0) {
					[[NSRunLoop currentRunLoop] runUntilDate: [NSDate date]];
				}
				dispatch_async(dispatch_get_main_queue(), ^() {
					[bctrl _replaceIntervalElapsed];	
					showTestBanner();
				});
			});			
 		}

 	} else {
	 	[bctrl _replaceIntervalElapsed];
	 	[bctrl _dismissIntervalElapsed];
	 	showTestBanner();
 	}
}

%ctor {
	TLog(@"Initialized");
	
	reloadPreferences();

	CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
	CFNotificationCenterAddObserver(center, NULL, &prefsChanged, (CFStringRef)@"com.alexzielenski.tinybar/prefsChanged", NULL, 0);
}
