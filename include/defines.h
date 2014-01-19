#define TLog(format, ...) NSLog(@"TinyBar: %@", [NSString stringWithFormat: format, ## __VA_ARGS__])

#define PREFS_PATH [NSString stringWithFormat:@"%@/Library/Preferences/com.alexzielenski.tinybar.plist", NSHomeDirectory()]
#define DEFAULT_DURATION 6.375
#define DEFAULT_SPEED 85.0
#define DEFAULT_HEIGHT 20.0
#define DEFAULT_ENABLED YES

#define PREFS_DURATION_KEY @"duration"
#define PREFS_SPEED_KEY @"speed"
#define PREFS_HEIGHT_KEY @"height"
#define PREFS_ENABLED_KEY @"enabled"

#define DEFAULT_PREFS [NSDictionary dictionaryWithObjectsAndKeys: @DEFAULT_DURATION, PREFS_DURATION_KEY, @DEFAULT_SPEED, PREFS_SPEED_KEY, @DEFAULT_HEIGHT, PREFS_HEIGHT_KEY, @DEFAULT_ENABLED, PREFS_HEIGHT_KEY, nil]