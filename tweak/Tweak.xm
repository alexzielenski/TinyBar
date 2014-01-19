#import <substrate.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "MarqueeLabel.h"
#import <defines.h>

#define PADDING   4.0
#define IMAGESIZE 14.0

#define SBHEIGHT round([preferences objectForKey: PREFS_HEIGHT_KEY] ? [[preferences objectForKey: PREFS_HEIGHT_KEY] doubleValue] : DEFAULT_HEIGHT)
#define DURATION  [preferences objectForKey: PREFS_DURATION_KEY] ? [[preferences objectForKey: PREFS_DURATION_KEY] doubleValue] : DEFAULT_DURATION
#define SCROLL_SPEED [preferences objectForKey: PREFS_SPEED_KEY] ? [[preferences objectForKey: PREFS_SPEED_KEY] doubleValue] : DEFAULT_SPEED
#define ENABLED ([preferences objectForKey: PREFS_ENABLED_KEY] ? [[preferences objectForKey: PREFS_ENABLED_KEY] boolValue] : DEFAULT_ENABLED)
#define SHOWTITLE ([preferences objectForKey: PREFS_SHOWTITLE_KEY] ? [[preferences objectForKey: PREFS_SHOWTITLE_KEY] boolValue] : DEFAULT_SHOWTITLE)

static NSDictionary *preferences = nil;

%hook SBDefaultBannerView

-(void)layoutSubviews {
	%orig;

	UIImageView *attachment = MSHookIvar<UIImageView *>(self, "_attachmentImageView");
	UIView *textView = MSHookIvar<UIView *>(self, "_textView");
	UIView *imageView = MSHookIvar<UIView *>(self, "_iconImageView");
	UIView *grabberView = MSHookIvar<UIView *>(self, "_grabberView");

	if (!ENABLED) {
		attachment.alpha = 1.0;
		grabberView.alpha = 1.0;
		return;
	}

	// Hide the grabber
	grabberView.alpha = 0.0;
	
	// Get rid of the attachment
	attachment.alpha = 0.0;

	CGRect bounds = [(UIView *)self bounds];
	CGFloat height = SBHEIGHT;

	// Make the image our size and vertically center it
	CGRect imageFrame = CGRectZero;
	imageFrame.origin.y = floor(height / 2 - IMAGESIZE / 2);
	imageFrame.origin.x = 0;
	imageFrame.size.height = IMAGESIZE;
	imageFrame.size.width = IMAGESIZE;
	[imageView setFrame: imageFrame];

	// Place the content view PADDING distance away from the image view
	// and make it fill the rest of the view
	CGRect textFrame = textView.frame;
	textFrame.size.height = bounds.size.height;
	textFrame.origin.x = imageFrame.origin.x + imageFrame.size.width + PADDING;
	textFrame.origin.y = 0;
	textFrame.size.width = bounds.size.width - textFrame.origin.x;
	[textView setFrame: textFrame];
}

%end

%hook SBBannerController

-(CGRect)_bannerFrameForOrientation:(int)arg1 {
	CGRect o = %orig;
	if (!ENABLED)
		return o;

	if (o.size.width == 0 || o.size.height == 0)
		return o;

	// Make the banner window the height of the statusbar
	o.size.height = SBHEIGHT;
	return o;
}

%end

@interface NSObject ()
@property (assign,nonatomic) UIEdgeInsets clippingInsets;
-(BOOL)containsAttachments;
- (void)setSecondaryText:(id)arg1 italicized:(BOOL)arg2;
-(int)_ui_resolvedTextAlignment;
@end

%hook SBBannerContextView

-(void)setClippingInsets:(UIEdgeInsets)arg1 {
	if (ENABLED)
		%orig(UIEdgeInsetsZero);
	else
		%orig;
}

-(CGRect)_contentFrame {
	// For iPad: make the notification banners the entire width of the screen
	// rather than having them be tiny
	CGRect o = %orig;
	if (!ENABLED)
		return o;

	if (o.size.width == 0 || o.size.height == 0)
		return o;

	return CGRectInset([(UIView *)self bounds], PADDING, 0);
}

%end

%hook SBDefaultBannerTextView
const char *TEXTLABELPRIMARY;
const char *TEXTLABELSECONDARY;
const char *TEXTLABELDATE;
- (void)layoutSubviews {
	%orig;

	// Remove date label on iOS7.1
	Ivar labelVar = class_getInstanceVariable([self class], "_relevanceDateLabel");
	if (labelVar != NULL) {
		UILabel *dateLabel = object_getIvar(self, labelVar);
		if (dateLabel && [dateLabel isKindOfClass: %c(UILabel)]) {
			
			if (!ENABLED)
				[dateLabel setAlpha: 1.0];
			else
				[dateLabel setAlpha: 0.0];

			// [dateLabel removeFromSuperview];
		}
	}
	CGRect bounds = [(UIView *)self bounds];

	// Create and cache a primary text label
	UILabel *primary = objc_getAssociatedObject(self, &TEXTLABELPRIMARY);
	if (!primary) {
		primary = [[[UILabel alloc] initWithFrame: CGRectMake(0, 0, 20, bounds.size.height)] autorelease];
		objc_setAssociatedObject(self, &TEXTLABELPRIMARY, primary, OBJC_ASSOCIATION_RETAIN);
	}

	// Create and cache the secondary text label
	MarqueeLabel *secondary = objc_getAssociatedObject(self, &TEXTLABELSECONDARY);

	if (!secondary) {
		secondary = [[[MarqueeLabel alloc] initWithFrame: CGRectMake(0, 0, 1024, bounds.size.height) rate:SCROLL_SPEED andFadeLength:PADDING] autorelease];
		[secondary setAnimationDelay: 0.2];
		// loop scrolling
		[secondary setMarqueeType: MLContinuous];
		objc_setAssociatedObject(self, &TEXTLABELSECONDARY, secondary, OBJC_ASSOCIATION_RETAIN);
	}
	secondary.rate = SCROLL_SPEED;

	if (!ENABLED) {
		[primary removeFromSuperview];
		[secondary removeFromSuperview];
		return;
	}

	// get our strings from ivars
	NSAttributedString *primaryString = MSHookIvar<NSAttributedString *>(self, "_primaryTextAttributedStringComponent");
	NSAttributedString *secondaryString = MSHookIvar<NSAttributedString *>(self, "_secondaryTextAttributedString");
	// UIImage *image = MSHookIvar<UIImage *>(self, "_primaryTextAccessoryImageComponent");

	BOOL rtl = [secondaryString _ui_resolvedTextAlignment] == NSTextAlignmentRight || [primaryString _ui_resolvedTextAlignment] == NSTextAlignmentRight;

	// find the sizes of our text
	CGRect primaryRect   = [primaryString boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, bounds.size.height) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
	CGRect secondaryRect = [secondaryString boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, bounds.size.height) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];

	// vertically center the title
	primaryRect.origin.y = floor(bounds.size.height / 2 - primaryRect.size.height / 2);

	if (rtl) {
		primaryRect.origin.x = bounds.size.width + bounds.origin.x - primaryRect.size.width;
	}

	[primary setAttributedText: primaryString];

	if (!SHOWTITLE) {
		primaryRect.size.width = 0;
		[primary removeFromSuperview];
	} else {
		[primary setFrame: primaryRect];
		[self addSubview: primary];
	}

	// make the secondary text fille the rest of the view and vertically center it
	secondaryRect.origin.y    = floor(bounds.size.height / 2 - secondaryRect.size.height / 2) + 1.0;
	secondaryRect.origin.x   += primaryRect.size.width;
	secondaryRect.size.width  = bounds.size.width - secondaryRect.origin.x;

	if (rtl) {
		[secondary setMarqueeType: MLContinuousReverse];
		secondaryRect.origin.x = 0;
	} else {
		[secondary setMarqueeType: MLContinuous];
	}

	[secondary setTextAlignment: [secondaryString _ui_resolvedTextAlignment]];
	[secondary setFrame: secondaryRect];
	[secondary setAttributedText: secondaryString];
	[self addSubview: secondary];
}

- (void)drawRect:(CGRect)arg1 {
	// overriding so it does nothing
	if (!ENABLED)
		%orig(arg1);
}

- (void)setSecondaryText:(id)arg1 italicized:(BOOL)arg2 {
	// Add two spaces to the end of the secondary text to space out the marquee
	if (![arg1 hasSuffix: @"   "] && ENABLED)
		arg1 = [arg1 stringByAppendingString:@"  "];
	%orig(arg1, arg2);
}

%end

%hook SBBannerController

- (void)performSelector:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay inModes:(NSArray *)modes {
	if (sel_isEqual(aSelector, @selector(_dismissIntervalElapsed)) && ENABLED) {
		%orig(aSelector, anArgument, DURATION, modes);
	} else {
		%orig;
	}
}

%end


static inline void prefsChanged(CFNotificationCenterRef center,
									void *observer,
									CFStringRef name,
									const void *object,
									CFDictionaryRef userInfo) {

	TLog(@"Preferences changed!");
	if (preferences) {
		[preferences release];
		preferences = nil;
	}

	preferences = [[NSDictionary dictionaryWithContentsOfFile: PREFS_PATH] retain];
}

%ctor {
	TLog(@"Initialized");

	preferences = [[NSDictionary dictionaryWithContentsOfFile: PREFS_PATH] retain];
	if (!preferences) {
		preferences = DEFAULT_PREFS;
	}

	CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
	CFNotificationCenterAddObserver(center, NULL, &prefsChanged, (CFStringRef)@"com.alexzielenski.tinybar/prefsChanged", NULL, 0);
}
