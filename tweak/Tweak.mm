#include "Resources.h"

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
	if (grabberVar != NULL)
		grabberView = object_getIvar(self, grabberVar);
	
	Ivar secondaryContentVar = class_getInstanceVariable([self class], "_secondaryContentView");
	if (secondaryContentVar != NULL)
		secondaryContentView = object_getIvar(self, secondaryContentVar);

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

- (CGRect)_bannerFrameForOrientation:(NSInteger)orientation {
	_pulledDown = NO;
	
	id bulletin = [self valueForKeyPath: @"_bannerView.bannerContext.item.seedBulletin"];
	if (isApplicationBlacklisted([bulletin sectionID])) {
		// TLog(@"blacklisted");
		_pulledDown = YES;
	}
	
	CGRect o = %orig(orientation);
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

- (CGRect)_bannerFrameForOrientation:(NSInteger)orientation {
	// %log;
	_pulledDown = NO;
	
	id bulletin = [self valueForKeyPath: @"_bannerContext.item.seedBulletin"];
	if (isApplicationBlacklisted([bulletin sectionID]) || [self isPulledDown]) {
		TLog(@"blacklisted");
		_pulledDown = YES;
	}

	CGRect o = %orig(orientation);
	if (!ENABLED || _pulledDown)
		return o;
	
	if (o.size.width == 0 || o.size.height == 0)
		return o;
	
	// Make the banner window the height of the statusbar
	o.size.height = SBHEIGHT;
	return o;
}

- (void)setBannerPullPercentage:(CGFloat)percent {
	//Disable tinybar
	// %log;
	if (percent > 0.45)
		_pulledDown = YES;
	%orig(percent);
}

%end

%hook SBBannerContextView

- (void)setClippingInsets:(UIEdgeInsets)insets {
	if (ENABLED && !_pulledDown)
		%orig(UIEdgeInsetsZero);
	else
		%orig(insets);
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

- (void)layoutSubviews {
	%orig;
	if (ENABLED) {
		UIBackdropView *_backdropView = MSHookIvar<UIBackdropView *>(self, "_backdropView");

		if ([BGCOLOR isKindOfClass:NSClassFromString(@"NSNumber")])
			[_backdropView transitionToStyle:[BGCOLOR intValue]];
		else if ([BGCOLOR isKindOfClass:NSClassFromString(@"UIColor")] || [NSStringFromClass([BGCOLOR class]) isEqualToString:@"UIDeviceRGBColor"])
			[_backdropView transitionToColor:(UIColor *)BGCOLOR];
	}
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
	if (fontName && fontName.length && ![fontName isEqualToString:DEFAULT_FONT] && string) {
		NSMutableAttributedString *mut = [string.mutableCopy autorelease];
		UIFont *font = [UIFont fontWithName:fontName size:14.0];
		[mut addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, mut.length)];
		
		UIFont *newFont = [self scaledFont:font fromSize:mut.size toRect:bounds];
		[mut addAttribute:NSFontAttributeName value:newFont range:NSMakeRange(0, mut.length)];
		return mut;
	}
	return string;
}

%new
- (NSAttributedString *)tb_addFontColor:(NSString *)colorString toString:(NSAttributedString *)string {
	if (colorString && ![colorString isEqualToString:@"Default"] && string) {
		NSMutableAttributedString *mut = [string.mutableCopy autorelease];
		UIColor *color = [PRESET_COLORS objectForKey:colorString];
		[mut addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, mut.length)];
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
		if (dateLabel && [dateLabel isKindOfClass: NSClassFromString(@"UILabel")]) {
			
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
	
	if ((!secondaryText || secondaryText.length == 0) && IOS_8_PLUS()) {
		secondaryAtr = MSHookIvar<NSAttributedString *>(self, "_alternateSecondaryTextAttributedString");
		secondaryText = [secondaryAtr.string ?: @"" stringByReplacingOccurrencesOfString: @"\n" withString: @" "];
	}
	
	if (IOS_8_PLUS() && secondaryText) {
		secondaryString = [[self _newAttributedStringForSecondaryText:secondaryText
														 italicized:[self _isItalicizedAttributedString:secondaryAtr]] autorelease];
	} else if (secondaryText) {
		secondaryString = [[[NSAttributedString alloc] initWithString:secondaryText attributes:[secondaryAtr attributesAtIndex:0 effectiveRange:nil]] autorelease];
	}
	
	if (!primaryString)
		primaryString = [[NSAttributedString alloc] initWithString:@"" attributes: @{}];
	if (!secondaryString)
		secondaryString = [[NSAttributedString alloc] initWithString:@"" attributes: @{}];

	// Format Colors
	primaryString = [self tb_addFontColor:FONTCOLOR toString:primaryString];
	secondaryString = [self tb_addFontColor:FONTCOLOR toString:secondaryString];
	
	// Format Fonts
	primaryString = [self tb_addFont:FONT toString:primaryString bounds:bounds];
	secondaryString = [self tb_addFont:MESSAGEFONT toString:secondaryString bounds:bounds];

	UIFont *primaryFont = [primaryString attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
	UIFont *secondaryFont = [secondaryString attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];

	NSString *strRep = secondaryString.string;
	NSString *isoLangCode = [(NSString *)CFStringTokenizerCopyBestStringLanguage((CFStringRef)strRep, CFRangeMake(0, strRep.length)) autorelease];
	NSLocaleLanguageDirection direction = (NSLocaleLanguageDirection)[NSClassFromString(@"NSLocale") characterDirectionForLanguage:isoLangCode];

	BOOL rtl = (direction == NSLocaleLanguageDirectionRightToLeft);
	
	[primary setAttributedText:primaryString];
	[secondary setTextAlignment:(rtl) ? NSTextAlignmentRight : NSTextAlignmentLeft];
	[secondary setAttributedText:secondaryString];
	
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
	CGFloat primaryBase = bounds.size.height / 2 - primaryFont.lineHeight / 2;
	// Align the secondary text baseline to the primary
	CGFloat secondaryBase = primaryBase + (primaryFont.ascender - secondaryFont.ascender);

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
	[secondary setFrame:secondaryRect];
	[self addSubview:secondary];
	
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

	if (!IOS_8_PLUS()) {
		// The dismiss scheduling is run after this method is called
		// so it always uses intervals from the previous banner. Cancel/Reapply them
		id bctrl = [NSClassFromString(@"SBBannerController") sharedInstance];
		[NSObject cancelPreviousPerformRequestsWithTarget:bctrl selector:@selector(_replaceIntervalElapsed) object: nil];
		[NSObject cancelPreviousPerformRequestsWithTarget:bctrl selector:@selector(_dismissIntervalElapsed) object: nil];
		
		[bctrl performSelector:@selector(_replaceIntervalElapsed) withObject:nil afterDelay:_replaceInterval];
		[bctrl performSelector:@selector(_dismissIntervalElapsed) withObject:nil afterDelay:_dismissInterval];
	}
}

- (void)drawRect:(CGRect)rect {
	// overriding so it does nothing
	if (!ENABLED || _pulledDown)
		%orig(rect);
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
	[self tb_setTitleLabel:nil];
	[self tb_setSecondaryLabel:nil];
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

	id bctrl = [NSClassFromString(@"SBBannerController") sharedInstance];
	// id ctrl = [%c(SBBulletinBannerController) sharedInstance];

	[NSObject cancelPreviousPerformRequestsWithTarget:bctrl selector:@selector(_replaceIntervalElapsed) object:nil];
	[NSObject cancelPreviousPerformRequestsWithTarget:bctrl selector:@selector(_dismissIntervalElapsed) object:nil];

    // Hide previous banner
 	if (IOS_8_PLUS()) {
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
	CFNotificationCenterAddObserver(center, NULL, &prefsChanged, (CFStringRef)@"com.iexiled.bannerstatus/prefsChanged", NULL, 0);
}
