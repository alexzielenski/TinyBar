include theos/makefiles/common.mk

ARCHS  := armv7 armv7s arm64
TARGET := iphone:7.0:7.0

TWEAK_NAME = TinyBar
TinyBar_FILES = Tweak.xm
TinyBar_FRAMEWORKS = UIKit CoreGraphics QuartzCore
TinyBar_LIBRARIES = substrate
TinyBar_LDFLAGS = -L$(THEOS_PROJECT_DIR)/tweak/lib -lmarquee
TinyBar_CFLAGS = -I../include

include $(THEOS_MAKE_PATH)/tweak.mk
