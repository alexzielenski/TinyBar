#import <substrate.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "MarqueeLabel.h"

#define TLog(format, ...) NSLog(@"TinyBar: %@", [NSString stringWithFormat: format, ## __VA_ARGS__])
#define PADDING   4.0
#define SBHEIGHT  20.0
#define IMAGESIZE 14.0

%hook SBDefaultBannerView

-(void)layoutSubviews {
	%orig;

	UIView *textView = MSHookIvar<UIView *>(self, "_textView");
	UIView *imageView = MSHookIvar<UIView *>(self, "_iconImageView");
	UIView *grabberView = MSHookIvar<UIView *>(self, "_grabberView");
	UIImageView *attachment = MSHookIvar<UIImageView *>(self, "_attachmentImageView");

	// Hide the grabber
	[grabberView setAlpha: 0.0];
	
	// Get rid of the attachment
	if (attachment) {
		[attachment removeFromSuperview];
		// [attachment release];
		// attachment = nil;
	}

	CGRect bounds = [(UIView *)self bounds];

	// Make the image our size and vertically center it
	CGRect imageFrame = CGRectZero;
	imageFrame.origin.y = floor(SBHEIGHT / 2 - IMAGESIZE / 2);
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
	%orig(UIEdgeInsetsZero);
}

-(CGRect)_contentFrame {
	// For iPad: make the notification banners the entire width of the screen
	// rather than having them be tiny
	CGRect o = %orig;
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
		secondary = [[[MarqueeLabel alloc] initWithFrame: CGRectMake(0, 0, 1024, bounds.size.height) rate:85.0 andFadeLength:PADDING] autorelease];
		[secondary setAnimationDelay: 0.2];
		// loop scrolling
		[secondary setMarqueeType: MLContinuous];
		objc_setAssociatedObject(self, &TEXTLABELSECONDARY, secondary, OBJC_ASSOCIATION_RETAIN);
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
	[primary setFrame: primaryRect];
	[self addSubview: primary];

	// make the secondary text fille the rest of the view and vertically center it
	secondaryRect.origin.y    = floor(bounds.size.height / 2 - secondaryRect.size.height / 2) + 1.0;
	secondaryRect.origin.x   += primaryRect.size.width + PADDING;
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
}

- (void)setPrimaryText:(NSString *)arg1 {
	// Add a colon to the title
	if (![arg1 hasSuffix: @":"])
		arg1 = [arg1 stringByAppendingString:@":"];
	%orig(arg1);
}

- (void)setSecondaryText:(id)arg1 italicized:(BOOL)arg2 {
	// Add two spaces to the end of the secondary text to space out the marquee
	if (![arg1 hasSuffix: @"  "])
		arg1 = [arg1 stringByAppendingString:@"  "];
	%orig(arg1, arg2);
}

- (void)setRelevanceDateText:(id)arg1 {
	// Clear the relevance string ("now")
	%orig(@"");
}

-(void)setPrimaryTextAccessoryImage:(id)arg1 {
	%orig(nil);
}

%end

%ctor {
	TLog(@"Initialized");
}
