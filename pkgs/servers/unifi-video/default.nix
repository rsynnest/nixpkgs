{ dpkg
, stdenv
, lib
, fetchurl
}:

stdenv.mkDerivation rec {
  pname = "unifi-video";
  version = "3.10.13";
  src = fetchurl {
    url = "https://dl.ui.com/firmwares/ufv/v${version}/unifi-video.Debian9_amd64.v${version}.deb";
    sha256 = "06mxjdizs4mhm1by8kj4pg5hhdi8ns6x75ggwyp1k6zb26jvvdny";
  };

  nativeBuildInputs = [ dpkg ];

  unpackCmd = ''
#    runHook preUnpack

    dpkg-deb -x $src .
    rm -r ./etc

#    runHook postUnpack
  '';

  installPhase = ''
#    runHook preinstall

    mkdir -p $out
    cp -ar sbin $out/bin
    cp -ar lib share $out
    chmod +x $out/bin/*

#    runHook postInstall
  '';

  meta = with lib; {
    description = "Unifi Video NVR (aka Airvision)";
    longDescription = ''
      Unifi Video is the NVR server software which can monitor and
      record footage from supported Unifi video cameras
    '';
    homepage = "https://www.ui.com";
    downloadPage = "https://www.ui.com/download/unifi-video/";
    license = licenses.unfree;
    maintainers = [ maintainers.rsynnest ];
    platforms = [ "x86_64-linux" ];
  };
}
