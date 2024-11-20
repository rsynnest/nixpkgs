{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,

  # for addons
  buildNpmPackage,
  zip,
}:

buildGoModule rec {
  pname = "omnom";
  version = "0-unstable-2024-10-01";

  src = fetchFromGitHub {
    owner = "asciimoo";
    repo = "omnom";
    rev = "5e82dd40a36b38572b12fa8cbee6097bb40b499d";
    hash = "sha256-IhiiabJZi+UFvtmgfxLBeuUghB64qiaR4zk3Yotld7g=";
    fetchSubmodules = true;
  };

  vendorHash = "sha256-dsS5w8JXIwkneWScOFzLSDiXq+clgK+RdYiMw0+FnvY=";

  patches = [ ./0001-fix-minimal-go-version.patch ];

  nativeBuildInputs = [ makeWrapper ];

  ldflags = [
    "-s"
    "-w"
  ];

  postBuild =
    let
      omnom-addons = buildNpmPackage {
        pname = "omnom-addons";
        inherit version src;

        npmDepsHash = "sha256-sUn5IvcHWJ/yaqeGz9SGvGx9HHAlrcnS0lJxIxUVS6M=";
        sourceRoot = "${src.name}/ext";
        npmPackFlags = [ "--ignore-scripts" ];

        nativeBuildInputs = [ zip ];

        postBuild = ''
          mkdir -p $out

          zip -r "$out/omnom_ext_src.zip" README.md src utils package* webpack.config.js

          pushd build
            zip "$out/omnom_ext_chrome.zip" ./* icons/* -x manifest_ff.json
            zip "$out/omnom_ext_firefox.zip" ./* icons/* -x manifest_ff.json
          popd
        '';

        postCheck = ''
          npm run build-test
        '';
      };
    in
    ''
      mkdir -p $out/share/addons

      # Copy Firefox and Chrome addons
      cp -r ${omnom-addons}/*.zip $out/share/addons
    '';

  postInstall = ''
    mkdir -p $out/share/examples

    cp -r static templates $out/share
    cp config.yml_sample $out/share/examples/config.yml
  '';

  meta = {
    description = "A webpage bookmarking and snapshotting service";
    homepage = "https://github.com/asciimoo/omnom";
    license = lib.licenses.agpl3Only;
    maintainers = lib.teams.ngi.members;
    mainProgram = "omnom";
  };
}
