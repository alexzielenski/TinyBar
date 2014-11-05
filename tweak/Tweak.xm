#import <substrate.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "MarqueeLabel.h"
#import <defines.h>

#define PADDING   4.0
#define IMAGESIZE 14.0

#define SBHEIGHT round([preferences objectForKey: PREFS_HEIGHT_KEY] ? [[preferences objectForKey: PREFS_HEIGHT_KEY] doubleValue] : DEFAULT_HEIGHT)
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
+ (id)action;
+ (id)sharedInstance;
- (void)observer:(id)arg1 addBulletin:(id)arg2 forFeed:(NSInteger)arg3;
- (void)_replaceIntervalElapsed;
- (void)_dismissIntervalElapsed;
- (BOOL)containsAttachments;
- (void)setSecondaryText:(id)arg1 italicized:(BOOL)arg2;
- (int)_ui_resolvedTextAlignment;

- (UILabel *)tb_titleLabel;
- (MarqueeLabel *)tb_secondaryLabel;
- (void)tb_setTitleLabel:(UILabel *)label;
- (void)tb_setSecondaryLabel:(UILabel *)label;

- (void)tb_createLabelsIfNecessary;
- (NSAttributedString *)tb_addFont:(NSString *)font toString:(NSAttributedString *)string;

- (void)_cancelBannerDismissTimers;
- (void)_setUpBannerDismissTimers;

- (BOOL)_isItalicizedAttributedString:(NSAttributedString *)arg1;
- (NSAttributedString *)_newAttributedStringForSecondaryText:(NSString *)arg1 italicized:(BOOL)arg2;
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

%hook SBDefaultBannerView

- (void)layoutSubviews {
	%orig;
	
	UIImageView *attachment = MSHookIvar<UIImageView *>(self, "_attachmentImageView");
	UIView *textView = MSHookIvar<UIView *>(self, "_textView");
	UIView *imageView = MSHookIvar<UIView *>(self, "_iconImageView");
	UIView *grabberView = nil;

	// The grabber view was removed in iOS 8
	Ivar grabberVar = class_getInstanceVariable([self class], "_grabberView");
	if (grabberVar != NULL) {
		grabberView = object_getIvar(self, grabberVar);
	}

	if (!ENABLED || _pulledDown) {
		attachment.alpha = 1.0;
		grabberView.alpha = 1.0;
		return;
	}

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

- (void)_presentBannerForContext:(id)arg1 reason:(long long)arg2 {
	%log;
	%orig(arg1, arg2);
}

- (CGRect)_bannerFrameForOrientation:(int)arg1 {
	_pulledDown = NO;
	
	id bulletin = [self valueForKeyPath: @"_bannerView.bannerContext.item.seedBulletin"];
	if (isApplicationBlacklisted([bulletin sectionID])) {
		TLog(@"blacklisted");
		_pulledDown = YES;
	}
	
	CGRect o = %orig;
	if (!ENABLED || _pulledDown)
		return o;

	if (o.size.width == 0 || o.size.height == 0)
		return o;

	// Make the banner window the height of the statusbar
	o.size.height = SBHEIGHT;
	return o;
}

- (void)_setupBannerDismissTimers {
	%log;
	%orig;
}

- (void)_cancelBannerDismissTimers {
	%log;
	%orig;
}

- (void)performSelector:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay inModes:(NSArray *)modes {
	%log;
	   
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

- (void)_replaceIntervalElapsed {
    %log;
    %orig;
}

- (void)_dismissIntervalElapsed {
    %log;
    %orig;
}

%end

%hook SBBannerContainerViewController

- (CGRect)_bannerFrameForOrientation:(long long)arg1 {
%log;
	_pulledDown = NO;
	
	id bulletin = [self valueForKeyPath: @"_bannerContext.item.seedBulletin"];
	if (isApplicationBlacklisted([bulletin sectionID])) {
		TLog(@"blacklisted");
		_pulledDown = YES;
	}

	CGRect o = %orig;
	if (!ENABLED || _pulledDown)
		return o;
	
	if (o.size.width == 0 || o.size.height == 0)
		return o;
	
	// Make the banner window the height of the statusbar
	o.size.height = SBHEIGHT;
	return o;
}

- (void)_noteDidPullDown {
	//Disable tinybar
	%log;
	_pulledDown = YES;
	%orig;
}

%end

%hook SBBannerContextView

- (void)setClippingInsets:(UIEdgeInsets)arg1 {
	if (ENABLED && !_pulledDown)
		%orig(UIEdgeInsetsZero);
	else
		%orig;
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

- (double)_grabberAlpha {
	return ENABLED && !_pulledDown ? 0.0 : %orig;
}

- (double)minimumHeight {
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
- (NSAttributedString *)tb_addFont:(NSString *)fontName toString:(NSAttributedString *)string {
	if (fontName && fontName.length && ![fontName isEqualToString: @"Default"]) {
		NSMutableAttributedString *mut = [string.mutableCopy autorelease];
		[mut addAttribute: NSFontAttributeName value: [UIFont fontWithName: fontName size: 14.0] range: NSMakeRange(0, mut.length)];
		return mut;
	}
	
	return string;
}

- (void)layoutSubviews {
	%log;
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
	if (IS_IOS_8_PLUS()) {
		secondaryString = [[self _newAttributedStringForSecondaryText: secondaryText
														 italicized: [self _isItalicizedAttributedString: secondaryAtr]] autorelease];
	} else {
		secondaryString = [[[NSAttributedString alloc] initWithString: secondaryText attributes: [secondaryAtr attributesAtIndex: 0 effectiveRange: nil]] autorelease];
	}

	// Format Fonts
	primaryString = [self tb_addFont: FONT toString: primaryString];
	secondaryString = [self tb_addFont: MESSAGEFONT toString: secondaryString];

	NSString *strRep = secondaryString.string;
	NSString *isoLangCode = [(NSString *)CFStringTokenizerCopyBestStringLanguage((CFStringRef)strRep, CFRangeMake(0, strRep.length)) autorelease];
	NSLocaleLanguageDirection direction = (NSLocaleLanguageDirection)[%c(NSLocale) characterDirectionForLanguage:isoLangCode];

	BOOL rtl = (direction == NSLocaleLanguageDirectionRightToLeft);

	// find the sizes of our text
	CGRect primaryRect   = [primaryString boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, bounds.size.height) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
	CGRect secondaryRect = [secondaryString boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, bounds.size.height) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];

	[primary setAttributedText: primaryString];

	// vertically center the title
	primaryRect.origin.y = floor(bounds.size.height / 2 - primaryRect.size.height / 2);
	if (rtl) {
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
	secondaryRect.origin.y    = floor(bounds.size.height / 2 - secondaryRect.size.height / 2) + 1.0;
	secondaryRect.origin.x   += primaryRect.size.width + PADDING;
	secondaryRect.size.width  = bounds.size.width - primaryRect.size.width;

	if (rtl) {
		[secondary setMarqueeType: MLContinuousReverse];
		secondaryRect.origin.x = 0;
	} else {
		[secondary setMarqueeType: MLContinuous];
	}

	[secondary setTextAlignment: (rtl) ? NSTextAlignmentRight : NSTextAlignmentLeft];
	[secondary setAttributedText: secondaryString];
	
	// Align secondary baseline to the title
	CGFloat primaryBaseline = CGRectGetMaxY(primaryRect) + primary.font.descender;
	CGFloat secondaryBaseline = CGRectGetHeight(secondaryRect) + secondary.font.descender;
	secondaryRect.origin.y = ceil((primaryBaseline - secondaryBaseline));

	[secondary setFrame: secondaryRect];
	[self addSubview: secondary];
	
	//	Make the banner persist at least as long as the user says or enough for one scroll around
	CGFloat animationDuration = secondary.animationDuration * 2 + secondary.animationDelay;
	CGFloat dismissDuration = animationDuration > 0 ? DURATION_LONG : DURATION;
	CGFloat replaceDuration = (dismissDuration / DEFAULT_DURATION) * 2.375;
	
	if (animationDuration > replaceDuration && SCROLLTOEND && animationDuration > secondary.animationDelay) {
		replaceDuration = animationDuration;
		
		if (animationDuration > DURATION_LONG) {
			dismissDuration = animationDuration;
		}
	}
		
	_dismissInterval = dismissDuration;
	_replaceInterval = replaceDuration;	
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

	// Show a test notification
	id request = [[[%c(BBBulletinRequest) alloc] init] autorelease];
	[request setTitle: @"TinyBar"];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[request setMessage: @"Preferences saved!\nThis is a really really really really really really really really really really really really long test notification to show scrolling."];
	} else {
		[request setMessage: @"Preferences saved! This is an extra long test notification to show scrolling."];
	}
	[request setSectionID: @"com.apple.Preferences"];
	[request setDefaultAction: [%c(BBAction) action]];
  
	id bctrl = [%c(SBBannerController) sharedInstance];
	id ctrl = [%c(SBBulletinBannerController) sharedInstance];
	
	if (IS_IOS_8_PLUS()) {
		[bctrl _cancelBannerDismissTimers];
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:bctrl selector:@selector(_replaceIntervalElapsed) object:nil];
	[NSObject cancelPreviousPerformRequestsWithTarget:bctrl selector:@selector(_dismissIntervalElapsed) object:nil];

    // Hide previous banner
    [bctrl _replaceIntervalElapsed];
 	[bctrl _dismissIntervalElapsed];

    [ctrl observer:nil addBulletin:request forFeed:2];
}

%ctor {
	TLog(@"Initialized");
	
	reloadPreferences();

	CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
	CFNotificationCenterAddObserver(center, NULL, &prefsChanged, (CFStringRef)@"com.alexzielenski.tinybar/prefsChanged", NULL, 0);
}
