#
# Copyright (C) 2010-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=e2fsprogs
PKG_CPE_ID:=cpe:/a:e2fsprogs_project:e2fsprogs
PKG_VERSION:=1.45.5
PKG_HASH:=f9faccc0d90f73556e797dc7cc5979b582bd50d3f8609c0f2ad48c736d44aede
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_URL:=@KERNEL/linux/kernel/people/tytso/e2fsprogs/v$(PKG_VERSION)/

HOST_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/host-build.mk

ifneq ($(shell $(HOSTCC) --version | grep clang),)
  HOST_CFLAGS += -D__GNUC_PREREQ\(...\)=0
endif
HOST_CFLAGS += $(FPIC)

HOST_CONFIGURE_ARGS += \
	--disable-elf-shlibs \
	--enable-libuuid \
	--disable-tls \
	--disable-nls

define Host/Prepare
	$(call Host/Prepare/Default)
	rm -rf $(HOST_BUILD_DIR)/doc
endef

define Host/Install
	$(Host/Install/Default)
	$(MAKE) -C $(HOST_BUILD_DIR)/lib/uuid install
	mkdir -p $(STAGING_DIR_HOST)/include/e2fsprogs
	$(CP) $(STAGING_DIR_HOST)/include/uuid $(STAGING_DIR_HOST)/include/e2fsprogs/
	rm -rf $(STAGING_DIR_HOST)/include/uuid
	$(INSTALL_DATA) $(HOST_BUILD_DIR)/lib/uuid/libuuid.a $(STAGING_DIR_HOST)/lib/
endef

define Host/Clean
	rm -f $(STAGING_DIR_HOST)/bin/e2fsck
	rm -f $(STAGING_DIR_HOST)/bin/tune2fs
endef

$(eval $(call HostBuild))
