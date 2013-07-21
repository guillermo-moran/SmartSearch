TARGET = iphone:clang:latest:6.0
include theos/makefiles/common.mk

BUNDLE_NAME = SmartSearch
SmartSearch_FILES = SmartSearch.m
SmartSearch_INSTALL_PATH = /Library/SearchLoader/SearchBundles
SmartSearch_BUNDLE_EXTENSION = searchBundle
SmartSearch_LDFLAGS = -lspotlight
SmartSearch_FRAMEWORKS = Foundation CoreFoundation
SmartSearch_PRIVATE_FRAMEWORKS = Search 

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	mkdir -p $(THEOS_STAGING_DIR)/Library/SearchLoader/Applications
	cp -r InfoBundle/ $(THEOS_STAGING_DIR)/Library/SearchLoader/Applications/SmartSearch.bundle
