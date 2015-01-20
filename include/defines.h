#define TLog(format, ...) NSLog(@"\n\nBannerStatus: %@\n\n", [NSString stringWithFormat: format, ## __VA_ARGS__])

#define APPID @"com.iexiled.bannerstatus"
#define PREFS_PATH [NSString stringWithFormat:@"%@/Library/Preferences/%@.plist", NSHomeDirectory(), APPID]
#define DEFAULT_DURATION 6.375
#define DEFAULT_DURATION_LONG 10.375
#define DEFAULT_SPEED 85.0
#define DEFAULT_HEIGHT 20.0
#define DEFAULT_ENABLED YES
#define DEFAULT_BG_COLOR @"dark"
#define DEFAULT_SHOWTITLE YES
#define DEFAULT_SHOWICON YES
#define DEFAULT_STRETCH_BANNER YES
#define DEFAULT_SCROLLTOEND YES
#define DEFAULT_STICKY NO
#define DEFAULT_SHOWCOLON NO
#define DEFAULT_DELAY 0.2
#define DEFAULT_FONT @"Default"

#define PREFS_DURATION_KEY @"duration"
#define PREFS_SPEED_KEY @"speed"
#define PREFS_HEIGHT_KEY @"height"
#define PREFS_ENABLED_KEY @"enabled"
#define PREFS_BACKGROUND_KEY @"background"
#define PREFS_SHOWTITLE_KEY @"showTitle"
#define PREFS_DURATION_LONG_KEY @"durationLong"
#define PREFS_SHOWICON_KEY @"showIcon"
#define PREFS_STRETCH_BANNER_KEY @"stretchBanner"
#define PREFS_SCROLLTOEND_KEY @"scrollToEnd"
#define PREFS_STICKY_KEY @"sticky"
#define PREFS_FONT_KEY @"font"
#define PREFS_MESSAGEFONT_KEY @"messageFont"
#define PREFS_FONTCOLOR_KEY @"fontColor"
#define PREFS_SHOWCOLON_KEY @"showColon"
#define PREFS_DELAY_KEY @"animationDelay"

#define DEFAULT_PREFS [NSDictionary dictionaryWithObjectsAndKeys: @DEFAULT_SHOWCOLON, PREFS_SHOWCOLON_KEY, @DEFAULT_STICKY, PREFS_STICKY_KEY, @DEFAULT_SCROLLTOEND, PREFS_SCROLLTOEND_KEY, @DEFAULT_STRETCH_BANNER, PREFS_STRETCH_BANNER_KEY, @DEFAULT_SHOWICON, PREFS_SHOWICON_KEY, @DEFAULT_DURATION_LONG, PREFS_DURATION_LONG_KEY, @DEFAULT_SHOWTITLE, PREFS_SHOWTITLE_KEY, @DEFAULT_DURATION, PREFS_DURATION_KEY, @DEFAULT_SPEED, PREFS_SPEED_KEY, @DEFAULT_HEIGHT, PREFS_HEIGHT_KEY, @DEFAULT_ENABLED, PREFS_HEIGHT_KEY, @DEFAULT_DELAY, PREFS_DELAY_KEY,nil]

#define PRESET_COLORS @{@"Default" : [NSNumber numberWithInt:2050], @"Aqua" : [UIColor colorWithRed:127.0/255.0 green:219.0/255.0 blue:255/255.0 alpha:1.0], @"Black" : [UIColor colorWithRed:17.0/255.0 green:17.0/255.0 blue:17.0/255.0 alpha:1.0], @"Blue" : [UIColor colorWithRed:0.0/255.0 green:116.0/255.0 blue:217.0/255.0 alpha:1.0], @"Fuchsia" : [UIColor colorWithRed:240.0/255.0 green:18.0/255.0 blue:190.0/255.0 alpha:1.0], @"Grey" : [UIColor colorWithRed:170.0/255.0 green:170.0/255.0 blue:170.0/255.0 alpha:1.0], @"Green" : [UIColor colorWithRed:46.0/255.0 green:204.0/255.0 blue:64.0/255.0 alpha:1.0], @"Lime" : [UIColor colorWithRed:1.0/255.0 green:255.0/255.0 blue:112.0/255.0 alpha:1.0], @"Maroon" : [UIColor colorWithRed:133.0/255.0 green:20.0/255.0 blue:75.0/255.0 alpha:1.0], @"Navy" : [UIColor colorWithRed:0.0 green:31.0/255.0 blue:63.0/255.0 alpha:1.0], @"Olive" : [UIColor colorWithRed:61.0/255.0 green:153.0/255.0 blue:112.0/255.0 alpha:1.0], @"Orange" : [UIColor colorWithRed:255.0/255.0 green:133.0/255.0 blue:27.0/255.0 alpha:1.0], @"Purple" : [UIColor colorWithRed:177.0/255.0 green:13.0/255.0 blue:201.0/255.0 alpha:1.0], @"Red" : [UIColor colorWithRed:255.0/255.0 green:65.0/255.0 blue:54.0/255.0 alpha:1.0], @"Silver" : [UIColor colorWithRed:221.0/255.0 green:221.0/255.0 blue:221.0/255.0 alpha:1.0], @"Teal" : [UIColor colorWithRed:57.0/255.0 green:204.0/255.0 blue:204.0/255.0 alpha:1.0], @"White" : [UIColor whiteColor], @"Yellow" : [UIColor colorWithRed:255.0/255.0 green:220.0/255.0 blue:0.0 alpha:1.0]}



