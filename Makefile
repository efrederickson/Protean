ARCHS = armv7 armv7s arm64
THEOS_PACKAGE_DIR_NAME = debs

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Protean

Protean_FILES = Protean.mm \
				Tweak.xm \
                PRStatusApps.mm \
                UIStatusBarItemView.xm \
                FlipswitchHooks.xm Bluetooth.xm \
                LockscreenStatusBar.xm LSStatusTime.xm \
  	        BatteryPercent.xm \
		IntroView/PRIntroView.xm \
		IntroView/PRViewController.m \
		IntroView/PRPage1ViewController.m \
		IntroView/PRPage2ViewController.m \
		IntroView/PRFinalViewController.m \
		SignalRSSI.xm \
		Carrier.xm CustomTime.xm

Protean_FRAMEWORKS = UIKit CoreGraphics QuartzCore
Protean_LIBRARIES = activator objcipc flipswitch applist
Protean_PRIVATE_FRAMEWORKS = 

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Preferences"
SUBPROJECTS += proteansettings
include $(THEOS_MAKE_PATH)/aggregate.mk
