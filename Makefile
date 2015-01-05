ARCHS = armv7 armv7s arm64
THEOS_PACKAGE_DIR_NAME = debs
TARGET = iphone:7.1
CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Protean

Protean_FILES = Tweak.xm \
				Protean.mm \
                PRStatusApps.mm \
                UIStatusBarItemView.xm \
                FlipswitchHooks.xm Bluetooth.xm \
                LockscreenStatusBar.xm LSStatusTime.xm \
  	        BatteryPercent.xm \
		SignalRSSI.xm \
		Carrier.xm CustomTime.xm \
		PDFImage.m PDFImageOptions.m \
		UIStatusBarSpacerItemView.xm \
		proteansettings/libcolorpicker/UIColor+PFColor.m
#		SignalStrength.xm

LDFLAGS = -fobjc-arc

Protean_FRAMEWORKS = UIKit CoreGraphics QuartzCore
Protean_LIBRARIES = flipswitch IOKit MobileGestalt
#Protean_PRIVATE_FRAMEWORKS = PowerlogLoggerSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += proteansettings
include $(THEOS_MAKE_PATH)/aggregate.mk
