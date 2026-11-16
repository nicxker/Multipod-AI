TARGET := iphone:clang:latest:6.0
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = NicxkerAI

NicxkerAI_FILES = src/main.m \
                  src/AppDelegate.m \
                  src/ChatViewController.m \
                  src/SettingsViewController.m \
                  src/AIService.m \
                  src/MediaManager.m

NicxkerAI_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore AVFoundation CoreMedia
NicxkerAI_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable -Wno-error

include $(THEOS_MAKE_PATH)/application.mk

