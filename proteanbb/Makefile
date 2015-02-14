ARCHS = armv7 armv7s arm64
CFLAGS = -I../ -fno-objc-arc
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ProteanBB
ProteanBB_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
