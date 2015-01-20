BUNDLE_NAME = BannerStatus
BannerStatus_FILES = preferences.x BetterPSSliderTableCell.mm
BannerStatus_INSTALL_PATH = /Library/PreferenceBundles
BannerStatus_FRAMEWORKS = UIKit
BannerStatus_PRIVATE_FRAMEWORKS = Preferences BulletinBoard
BannerStatus_CFLAGS = -I$(THEOS_PROJECT_DIR)/include
BannerStatus_LIBRARIES = applist

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/BannerStatus.plist$(ECHO_END)
