{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
  ;
  inherit (config.hardware) mmcBootIndex;
  cfg = config.hardware.socs;
  nxpSOCs = [
    "nxp-imx8qm"
  ];
  anyNXP = lib.any (soc: config.hardware.socs.${soc}.enable) nxpSOCs;
  isPhoneUX = config.Tow-Boot.phone-ux.enable;
in
{
  options = {
    hardware.socs = {
      nxp-imx8qm.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when SoC is NXP i.MX8QuadMax";
        internal = true;
      };
    };
  };

  config = mkMerge [
    {
      hardware.socList = nxpSOCs;
    }
    (mkIf anyNXP {
      Tow-Boot = {
        # https://community.nxp.com/t5/i-MX-Processors-Knowledge-Base/i-MX8-Boot-process-and-creating-a-bootable-image/ta-p/1101253
        firmwarePartition = { # TODO CALCULATIONS
          offset = 32 * 1024; # 32KiB into the image, or 64 × 512 long sectors, or 0x8000
          length = 4 * 1024 * 1024; # Expected max size
        };
      };

    })
    (mkIf cfg.nxp-imx8qm.enable {
      system.system = "aarch64-linux";
      Tow-Boot.builder.additionalArguments = {
        BL31 = "${pkgs.Tow-Boot.armTrustedFirmwareIMX8QM}";
        FWDIR = "${pkgs.Tow-Boot.imxFirmware}";
      };
      Tow-Boot.config = [
          (helpers: with helpers; {
            # Enable EFI support
            CMD_BOOTEFI = yes;
            EFI_LOADER = yes;
            FIT = yes; #for BOOTM_EFI
            BOOTM_EFI = yes;
            CMD_BOOTEFI_HELLO = yes;
            CMD_BOOTEFI_SELFTEST = yes;
            DM_DEVICE_REMOVE = no;
            TOW_BOOT_MENU = yes;
            TOW_BOOT_MENU_CTRL_C_EXITS = yes;
          })
        ];
    })

    # Documentation fragments
    (mkIf (anyNXP && !isPhoneUX) {
      documentation.sections.installationInstructions =
        lib.mkDefault
        (config.documentation.helpers.genericInstallationInstructionsTemplate {
          # Assumed device-dependent as it is configurable:
          #  - https://community.nxp.com/t5/i-MX-Processors-Knowledge-Base/i-MX8-Boot-process-and-creating-a-bootable-image/ta-p/1101253
          startupConflictNote = ''

            > **NOTE**: The SoC startup order for NXP systems will be device-dependent.
            >
            > You may need to prevent default startup sources from being used
            > to install using the Tow-Boot installer image.

          '';
        })
      ;
    })
  ];
}
