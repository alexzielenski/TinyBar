include theos/makefiles/common.mk

BUNDLE_NAME = TinyBar
TinyBar_FILES = preferences.x
TinyBar_INSTALL_PATH = /Library/PreferenceBundles
TinyBar_FRAMEWORKS = UIKit
TinyBar_PRIVATE_FRAMEWORKS = Preferences BulletinBoard
TinyBar_CFLAGS = -I$(THEOS_PROJECT_DIR)/include
TinyBar_LIBRARIES = applist

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/TinyBar.plist$(ECHO_END)
