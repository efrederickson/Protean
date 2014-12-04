ARCHS = armv7 armv7s arm64
TARGET = iphone:7.1
CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ProteanSettings
ProteanSettings_FILES = ProteanSettings.mm \
  $(shell find $(THEOS)/include/SettingsKit -name '*.m') \
  PROrganizationController.mm AppsController.mm \
  IconSelectorController.mm PRFlipswitchController.mm \
  PRFSSelector.mm PRBluetoothController.mm PRSystemIconsController.mm \
  PRSysIconSelectorController.mm PRBTIconSelectorController.mm \
  PRMakersController.mm UIDiscreteSlider.m \
  $(shell find libcolorpicker -name '*.m') $(shell find libcolorpicker -name '*.mm')

ProteanSettings_INSTALL_PATH = /Library/PreferenceBundles
ProteanSettings_FRAMEWORKS = UIKit MessageUI Social QuartzCore CoreGraphics CoreBluetooth GraphicsServices
ProteanSettings_PRIVATE_FRAMEWORKS = Preferences BluetoothManager
ProteanSettings_LIBRARIES = applist flipswitch

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)cp $(THEOS)/include/SettingsKit/Resources/*.png $(THEOS_STAGING_DIR)/Library/PreferenceBundles/ProteanSettings.bundle/$(ECHO_END)
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ProteanSettings.plist$(ECHO_END)
