{ stdenv
, lib
, fetchurl
}:
let
  imxurl = "https://www.nxp.com/lgfiles/NMG/MAD/YOCTO";

  fwScVersion = "1.13.0";
  fwSecoVersion = "3.8.6";

  firmwareSc = fetchurl rec {
    url = "${imxurl}/imx-sc-firmware-${fwScVersion}.bin";
    sha256 = "YUaBIVCeOOTvifhiEIbKgyGsLZYufv5rs2isdSrw4dc=";
    executable = true;
  };

  firmwareSeco = fetchurl rec {
    url = "${imxurl}/imx-seco-${fwSecoVersion}.bin";
    sha256 = "eoG19xn283fsP2jP49hD4dIBRwEQqFQ9k3yVWOM8uKQ=";
    executable = true;
  };

  filesToInstall = [
    "imx-sc-firmware-${fwScVersion}/mx8qm-mek-scfw-tcm.bin"
    "imx-seco-${fwSecoVersion}/firmware/seco/mx8qmb0-ahab-container.img"
  ];

in
stdenv.mkDerivation {
  pname = "imxFirmware";
  version = "5.15.32_2.0.0-Yocto";

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  sourceRoot = ".";

  unpackPhase = ''
    ${firmwareSc} --auto-accept --force
    ${firmwareSeco} --auto-accept --force
  '';

  installPhase = ''
    mkdir -p $out
    cp -vt $out ${lib.concatStringsSep " " filesToInstall}
    mv $out/mx8qmb0-ahab-container.img $out/mx8qm-ahab-container.img
  '';

  meta = with lib; {
    description = "Firmware packages needed for booting i.MX8QM board";
    license = licenses.unfreeRedistributableFirmware;
  };
}
