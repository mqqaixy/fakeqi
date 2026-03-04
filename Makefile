TARGET := iphone:clang:latest
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FakeLocationPro
FakeLocationPro_FILES = Tweak.x
FakeLocationPro_FRAMEWORKS = UIKit CoreLocation

include $(THEOS_MAKE_PATH)/tweak.mk
