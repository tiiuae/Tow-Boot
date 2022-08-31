{ config, lib, pkgs, ... }:

let
  imxOpteeOs = pkgs.callPackage ./imx-optee-os.nix {inherit pkgs;};
in
{
  device = {
    manufacturer = "NXP";
    name = "i.MX8QuadMax";
    identifier = "mx8qm-mek";
  };

  hardware = {
    soc = "nxp-imx8qm";
  };

  Tow-Boot =  {

    uBootVersion = "2022.04";

    src = fetchGit {
        url = "https://source.codeaurora.org/external/imx/uboot-imx.git";
        ref = "lf_v2022.04";
    };

    defconfig = "imx8qm_mek_defconfig";

    useDefaultPatches = true;

    builder = {
      postPatch = ''
        install -m 0644 $BL31/bl31.bin ./
        install -m 0644 $FWDIR/* ./
        install -m 0644 ${imxOpteeOs}/tee.bin ./
        echo "IMAGE A35 tee.bin 0xfe000000" >> board/freescale/imx8qm_mek/uboot-container.cfg
      '';

      makeFlags = [ "spl/u-boot-spl.bin" "flash.bin" "-j32"];

      installPhase = ''
        install -m 0644 flash.bin $out/binaries/Tow-Boot.$variant.bin
      '';
    };

    # Does not build right now, anyway blind UX.
    withLogo = false;
  };
}
