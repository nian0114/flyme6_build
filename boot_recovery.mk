# boot_recovery.mk

######## Error Exit Num ##########
ERR_NOT_PREPARE_RECOVERY_IMG=211
ERR_NOT_PREPARE_BOOT_IMG=212

# Some custom defines
# vendor_modify_images := boot/boot.img recovery/recovery.img

UNPACK_BOOT_PY := $(PORT_ROOT)/tools/bootimgpack/unpack_bootimg.py
PACK_BOOT_PY := $(PORT_ROOT)/tools/bootimgpack/pack_bootimg.py
SEPOLICY_INJECT := $(PORT_ROOT)/build/tools/custom_sepolicy.sh
BOARD_SERVICE_PART := $(PORT_ROOT)/tools/bootimgpack/init.rc.part

######################## boot #############################
BOOT_IMG                 := boot.img
PRJ_BOOT_IMG             := $(PRJ_ROOT)/$(BOOT_IMG)
PRJ_BOOT_DIR             := $(PRJ_ROOT)/$(BOOT_IMG).out
VENDOR_BOOT              := $(VENDOR_DIR)/BOOT
SOURCE_BOOT              := $(BOARD_DIR)/BOOT
OUT_OBJ_BOOT             := $(OUT_OBJ_DIR)/BOOT
OUT_BOOT_IMG             := $(OUT_BOOTABLE_IMAGES)/$(BOOT_IMG)

SOURCE_BOOT_RAMDISK_SERVICEEXT  := $(SOURCE_BOOT)/RAMDISK/sbin/serviceext
OUT_OBJ_BOOT_RAMDISK_SERVICEEXT	:= $(OUT_OBJ_BOOT)/RAMDISK/sbin/serviceext
VENDOR_BOOT_KERNEL              := $(VENDOR_BOOT)/kernel
OUT_OBJ_BOOT_KERNEL             := $(OUT_OBJ_BOOT)/kernel

UNPACKBOOTIMG              := $(PORT_ROOT)/tools/$(HOST_OS)-x86/unpackbootimg
MKBOOTFS                   := $(PORT_ROOT)/tools/$(HOST_OS)-x86/mkbootfs
MKBOOTIMG                  := $(PORT_ROOT)/tools/$(HOST_OS)-x86/mkbootimg
PATCH_BOOTIMG_SH           := $(PORT_ROOT)/tools/patch_bootimg.sh

###### pack boot ######
bootimage:$(PATCH_BOOTIMG_SH) $(UNPACKBOOTIMG) $(MKBOOTFS) $(MKBOOTIMG)
	$(hide) echo "* build boot.img out ==> $(OUT_DIR)/$(BOOT_IMG)"
	$(hide) echo " "
	$(hide) echo ">> prepare boot ramdisk from $(PRJ_BOOT_DIR) ..."
	$(hide) mkdir -p $(OUT_BOOTABLE_IMAGES)
	$(hide) cp $(PRJ_BOOT_IMG) $(OUT_BOOT_IMG)
	@echo "Patching bootimg"
	$(hide) TARGET_BOOT_DIR=$(OUT_OBJ_BOOT) \
			$(if $(filter $(USE_ANDROID_OUT),true) ,,TARGET_BIT=$(PREBUILT_BIT)) \
			UNPACKBOOTIMG=$(UNPACKBOOTIMG) MKBOOTFS=$(MKBOOTFS) MKBOOTIMG=$(MKBOOTIMG) \
			bash $(PATCH_BOOTIMG_SH) $(OUT_BOOT_IMG)
	$(hide) echo "<< pack $(OUT_OBJ_BOOT) to $(OUT_DIR)/$(BOOT_IMG) done"

.PHONY: clean-bootimage
clean-bootimage:
	$(hide) rm -rf $(OUT_OBJ_BOOT) $(OUT_BOOT_IMG) $(OUT_DIR)/$(BOOT_IMG)
	$(hide) echo "<< clean-bootimage done"

######################## recovery #############################
RECOVERY_IMG            := recovery.img
PRJ_RECOVERY_IMG        := $(PRJ_ROOT)/$(RECOVERY_IMG)
PRJ_RECOVERY_FSTAB      := $(PRJ_ROOT)/recovery.fstab
VENDOR_RECOVERY         := $(VENDOR_DIR)/RECOVERY
SOURCE_RECOVERY         := $(BOARD_DIR)/RECOVERY
OUT_OBJ_RECOVERY        := $(OUT_OBJ_DIR)/RECOVERY
OUT_RECOVERY_IMG        := $(OUT_BOOTABLE_IMAGES)/$(RECOVERY_IMG)

VENDOR_RECOVERY_KERNEL       := $(VENDOR_RECOVERY)/kernel
VENDOR_RECOVERY_RAMDISK	     := $(VENDOR_RECOVERY)/RAMDISK
VENDOR_RECOVERY_FSTAB        := $(VENDOR_RECOVERY_RAMDISK)/etc/recovery.fstab
VENDOR_RECOVERY_DEFAULT_PROP := $(VENDOR_RECOVERY_RAMDISK)/default.prop
SOURCE_RECOVERY_RAMDISK      := $(SOURCE_RECOVERY)/RAMDISK
OUT_OBJ_RECOVERY_KERNEL      := $(OUT_OBJ_RECOVERY)/kernel
OUT_OBJ_RECOVERY_RAMDISK     := $(OUT_OBJ_RECOVERY)/RAMDISK
OUT_OBJ_RECOVERY_FSTAB       := $(OUT_OBJ_RECOVERY_RAMDISK)/etc/recovery.fstab
OUT_OBJ_RECOVERY_DEFAULT_PROP:= $(OUT_OBJ_RECOVERY_RAMDISK)/default.prop

###### unpack recovery ######

# unpack recovery.img to out/obj/RECOVERY
unpack-recovery:
	$(hide) echo ">> unpack  $(PRJ_RECOVERY_IMG) to $(OUT_OBJ_RECOVERY) ..."
	$(hide) if [ ! -e $(PRJ_RECOVERY_IMG) ];then \
			echo "<< ERROR: can not find $(PRJ_RECOVERY_IMG)!!";  \
			exit $(ERR_NOT_PREPARE_RECOVERY_IMG); \
		fi
	$(hide) rm -rf $(OUT_OBJ_RECOVERY)
	$(hide) $(UNPACK_BOOT_PY) $(PRJ_RECOVERY_IMG) $(OUT_OBJ_RECOVERY)
	$(hide) echo "<< unpack  $(PRJ_RECOVERY_IMG) to $(OUT_OBJ_RECOVERY) done"

###### pack recovery ######
ifeq ($(strip $(filter recovery recovery.img, $(vendor_modify_images))),)
ifeq ($(PRJ_RECOVERY_IMG), $(wildcard $(PRJ_RECOVERY_IMG)))
recoveryimage: $(OUT_RECOVERY_IMG) $(OUT_RECOVERY_FSTAB)
	$(hide) echo "* use prebuilt $(RECOVERY_IMG)"
	$(hide) echo " "

$(OUT_RECOVERY_IMG): $(PRJ_RECOVERY_IMG)
	$(hide) mkdir -p `dirname $@`
	$(hide) cp $(PRJ_RECOVERY_IMG) $@
	$(hide) cp $(PRJ_RECOVERY_IMG) $(OUT_DIR)
else
recoveryimage: $(OUT_RECOVERY_FSTAB)
	$(hide) echo "<< Nothing to do: $@"
endif

else
recoveryimage: $(OUT_RECOVERY_IMG) $(OUT_RECOVERY_FSTAB)
	$(hide) echo "* build recovery.img out ==> $(OUT_DIR)/$(BOOT_IMG)"
	$(hide) echo " "

RECOVERY_PREBUILT_FILES := $(VENDOR_RECOVERY_FSTAB):$(OUT_OBJ_RECOVERY_FSTAB)
RECOVERY_PREBUILT_FILES += $(VENDOR_BOOT_KERNEL):$(OUT_OBJ_RECOVERY_KERNEL)

.PHONY: prepare_recovery_ramdisk
prepare_recovery_ramdisk:
	$(hide) echo ">> prepare recovery ramdisk from $(PRJ_BOOT_DIR) ..."
	$(hide) rm -rf $(OUT_OBJ_RECOVERY)
	$(hide) mkdir -p $(OUT_OBJ_RECOVERY);
	$(hide) cp -r $(VENDOR_BOOT)/* $(OUT_OBJ_RECOVERY);
	$(hide) rm -rf $(OUT_OBJ_RECOVERY)/RAMDISK/;
	$(hide) cp -r $(SOURCE_RECOVERY)/RAMDISK/ $(OUT_OBJ_RECOVERY);
	$(hide) $(foreach prebuilt_pair,$(RECOVERY_PREBUILT_FILES),\
				$(eval src_file := $(call word-colon,1,$(prebuilt_pair)))\
				$(eval dst_file := $(call word-colon,2,$(prebuilt_pair)))\
				$(call file_copy,$(src_file),$(dst_file)))
	$(hide) echo "<< prepare recovery ramdisk from $(PRJ_BOOT_DIR) ..."

$(OUT_RECOVERY_IMG): prepare_recovery_ramdisk
	$(hide) echo ">> pack $(RECOVERY_IMG) ..."
	$(hide) if [ -f $(VENDOR_RECOVERY_DEFAULT_PROP) ];then \
			cat $(VENDOR_RECOVERY_DEFAULT_PROP) | grep -v '^ *#' | while read LINE; \
				do \
					prop_name=`echo $$LINE | awk -F= '{print $$1}' | sed 's/^ *//g;s/ *$$//g'`; \
					echo "   $(RECOVERY_IMG): override default.prop, prop name: $$prop_name, line: $$LINE"; \
					sed -i "/^ *$$prop_name *=/d" $(OUT_OBJ_RECOVERY_DEFAULT_PROP); \
				done; \
			cat $(VENDOR_RECOVERY_DEFAULT_PROP) >> $(OUT_OBJ_RECOVERY_DEFAULT_PROP); \
		fi
	$(hide) mkdir -p `dirname $@`
	$(hide) $(PACK_BOOT_PY) $(OUT_OBJ_RECOVERY) $@
	$(hide) cp $@ $(OUT_DIR)/$(RECOVERY_IMG)
	$(hide) echo "<< pack $(RECOVERY_IMG) done"
endif

$(OUT_RECOVERY_FSTAB): $(VENDOR_RECOVERY_FSTAB)
	$(hide) $(call file_copy,$(VENDOR_RECOVERY_FSTAB),$(OUT_RECOVERY_FSTAB))

.PHONY: clean-recoveryimage
clean-recoveryimage:
	$(hide) rm -rf $(OUT_OBJ_RECOVERY) $(OUT_RECOVERY) $(OUT_RECOVERY_IMG) $(OUT_DIR)/$(RECOVERY_IMG)
	$(hide) echo "<< clean-recoveryimage done"

.PHONY: bootimage.phone
bootimage.phone: bootimage $(OUT_META)/misc_info.txt $(OUT_RECOVERY_FSTAB)
	$(hide) $(FLASH) boot $(OUT_RECOVERY_FSTAB) $(OUT_BOOT_IMG) `awk -F= '/fstab_version=/{print $$2}' $(OUT_META)/misc_info.txt`


.PHONY: recoveryimage.phone
recoveryimage.phone: recoveryimage $(OUT_META)/misc_info.txt $(OUT_RECOVERY_FSTAB)
	$(hide) $(FLASH) recovery $(OUT_RECOVERY_FSTAB) $(OUT_RECOVERY_IMG) `awk -F= '/fstab_version=/{print $$2}' $(OUT_META)/misc_info.txt`

##############################################################
