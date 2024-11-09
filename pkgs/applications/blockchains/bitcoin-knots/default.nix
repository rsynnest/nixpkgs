{ lib
, stdenv
, fetchurl
, fetchpatch2
, autoreconfHook
, pkg-config
, util-linux
, hexdump
, autoSignDarwinBinariesHook
, wrapQtAppsHook ? null
, boost
, libevent
, miniupnpc
, zeromq
, zlib
, db48
, sqlite
, qrencode
, qtbase ? null
, qttools ? null
, python3
, withGui
, withWallet ? true
}:

stdenv.mkDerivation rec {
  pname = if withGui then "bitcoin-knots" else "bitcoind-knots";
  version = "26.1.knots20240325";

  src = fetchurl {
    url = "https://bitcoinknots.org/files/26.x/${version}/bitcoin-${version}.tar.gz";
    hash = "sha256-PqpePDna2gpCzF2K43N4h6cV5Y9w/e5ZcUvaNEaFaIk=";
  };

  patches = [
    # upnp: add compatibility for miniupnpc 2.2.8
    (fetchpatch2 {
      url = "https://github.com/bitcoinknots/bitcoin/commit/643014424359a4783cf9c73bee3346ac2f04e713.patch?full_index=1";
      hash = "sha256-FdLoNH3+ZZTbqrwRvhbAeJuGz4SgnIvoWUBzRxjfzs8=";
    })
  ];

  nativeBuildInputs =
    [ autoreconfHook pkg-config ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ util-linux ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [ hexdump ]
    ++ lib.optionals (stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64) [ autoSignDarwinBinariesHook ]
    ++ lib.optionals withGui [ wrapQtAppsHook ];

  buildInputs = [ boost libevent miniupnpc zeromq zlib ]
    ++ lib.optionals withWallet [ sqlite ]
    ++ lib.optionals (withWallet && !stdenv.hostPlatform.isDarwin) [ db48 ]
    ++ lib.optionals withGui [ qrencode qtbase qttools ];

  configureFlags = [
    "--with-boost-libdir=${boost.out}/lib"
    "--disable-bench"
  ] ++ lib.optionals (!doCheck) [
    "--disable-tests"
    "--disable-gui-tests"
  ] ++ lib.optionals (!withWallet) [
    "--disable-wallet"
  ] ++ lib.optionals withGui [
    "--with-gui=qt5"
    "--with-qt-bindir=${qtbase.dev}/bin:${qttools.dev}/bin"
  ];

  nativeCheckInputs = [ python3 ];

  doCheck = true;

  checkFlags =
    [ "LC_ALL=en_US.UTF-8" ]
    # QT_PLUGIN_PATH needs to be set when executing QT, which is needed when testing Bitcoin's GUI.
    # See also https://github.com/NixOS/nixpkgs/issues/24256
    ++ lib.optional withGui "QT_PLUGIN_PATH=${qtbase}/${qtbase.qtPluginPrefix}";

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Derivative of Bitcoin Core with a collection of improvements";
    homepage = "https://bitcoinknots.org/";
    changelog = "https://github.com/bitcoinknots/bitcoin/blob/v${version}/doc/release-notes.md";
    maintainers = with maintainers; [ prusnak mmahut ];
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
