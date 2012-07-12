include $(CLEAR_VARS)

BB_TC_DIR := $(realpath $(shell dirname $(TARGET_TOOLS_PREFIX)))
BB_TC_PREFIX := $(shell basename $(TARGET_TOOLS_PREFIX))
BB_LDFLAGS := -nostdlib -Bdynamic -Wl,-z,muldefs$(shell if test $(PLATFORM_SDK_VERSION) -lt 16; then echo -ne ',-T../../$(BUILD_SYSTEM)/armelf.x'; fi),-dynamic-linker,/system/bin/linker,-z,nocopyreloc,--no-undefined ../../$(TARGET_CRTBEGIN_DYNAMIC_O) ../../$(TARGET_CRTEND_O) -L../../$(TARGET_OUT_STATIC_LIBRARIES)
# FIXME remove -fno-strict-aliasing once all aliasing violations are fixed
BB_COMPILER_FLAGS := $(subst -I ,-I../../,$(subst -include ,-include ../../,$(TARGET_GLOBAL_CFLAGS))) -I../../bionic/libc/include -I../../bionic/libc/kernel/common -I../../bionic/libc/arch-arm/include -I../../bionic/libc/kernel/arch-arm -I../../bionic/libm/include -fno-stack-protector -Wno-error=format-security -fno-strict-aliasing
BB_LDLIBS := dl m c gcc
ifneq ($(strip $(SHOW_COMMANDS)),)
BB_VERBOSE="V=1"
endif

.PHONY: busybox

droid: busybox

systemtarball: busybox

busybox: $(TARGET_CRTBEGIN_DYNAMIC_O) $(TARGET_CRTEND_O) $(TARGET_OUT_STATIC_LIBRARIES)/libm.so $(TARGET_OUT_STATIC_LIBRARIES)/libc.so $(TARGET_OUT_STATIC_LIBRARIES)/libdl.so
	cd external/busybox && \
	sed -e "s|^CONFIG_CROSS_COMPILER_PREFIX=.*|CONFIG_CROSS_COMPILER_PREFIX=\"$(BB_TC_PREFIX)\"|;s|^CONFIG_EXTRA_CFLAGS=.*|CONFIG_EXTRA_CFLAGS=\"$(BB_COMPILER_FLAGS)\"|" configs/android_defconfig >.config && \
	export PATH=$(BB_TC_DIR):$(PATH) && \
	$(MAKE) oldconfig && \
	$(MAKE) $(BB_VERBOSE) EXTRA_LDFLAGS="$(BB_LDFLAGS)" LDLIBS="$(BB_LDLIBS)" && \
	mkdir -p ../../$(PRODUCT_OUT)/system/bin && \
	cp busybox ../../$(PRODUCT_OUT)/system/bin/
