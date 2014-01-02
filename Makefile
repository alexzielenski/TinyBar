export THEOS_DEVICE_IP = 127.0.0.1
export THEOS_DEVICE_PORT = 2222

ARCHS := armv7 armv7s arm64
TARGET := iphone:7.0:7.0

include theos/makefiles/common.mk

THEOS_BUILD_DIR = build

TWEAK_NAME = TinyBar
TinyBar_FILES = Tweak.xm
TinyBar_FRAMEWORKS = UIKit CoreGraphics QuartzCore
TinyBar_LIBRARIES = substrate
TinyBar_LDFLAGS = -L$(THEOS_PROJECT_DIR)/lib -lmarquee

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
