{
  # To test your changes in androidEnv run `nix-shell android-sdk-with-emulator-shell.nix`

  # If you copy this example out of nixpkgs, use these lines instead of the next.
  # This example pins nixpkgs: https://nix.dev/tutorials/first-steps/towards-reproducibility-pinning-nixpkgs.html
  /*nixpkgsSource ? (builtins.fetchTarball {
    name = "nixpkgs-20.09";
    url = "https://github.com/NixOS/nixpkgs/archive/20.09.tar.gz";
    sha256 = "1wg61h4gndm3vcprdcg7rc4s1v3jkm5xd7lw8r2f67w502y94gcy";
    }),
    pkgs ? import nixpkgsSource {
    config.allowUnfree = true;
    },
  */

  # If you want to use the in-tree version of nixpkgs:
  pkgs ? import ../../../../.. {
    config.allowUnfree = true;
  }
, config ? pkgs.config
}:

# Copy this file to your Android project.
let
  # Declaration of versions for everything. This is useful since these
  # versions may be used in multiple places in this Nix expression.
  android = {
    versions = {
      cmdLineToolsVersion = "13.0";
      platformTools = "35.0.2";
      buildTools = "35.0.0";
    };
    platforms = [ "35" ];
  };

  # If you copy this example out of nixpkgs, something like this will work:
  /*androidEnvNixpkgs = fetchTarball {
    name = "androidenv";
    url = "https://github.com/NixOS/nixpkgs/archive/<fill me in from Git>.tar.gz";
    sha256 = "<fill me in with nix-prefetch-url --unpack>";
    };

    androidEnv = pkgs.callPackage "${androidEnvNixpkgs}/pkgs/development/mobile/androidenv" {
    inherit config pkgs;
    licenseAccepted = true;
    };*/

  # Otherwise, just use the in-tree androidenv:
  androidEnv = pkgs.callPackage ./.. {
    inherit config pkgs;
    # You probably need to uncomment below line to express consent.
    # licenseAccepted = true;
  };

  sdkArgs = {
    cmdLineToolsVersion = android.versions.cmdLineToolsVersion;
    platformToolsVersion = android.versions.platformTools;
    buildToolsVersions = [ android.versions.buildTools ];
    platformVersions = android.platforms;
    includeNDK = false;
    includeSystemImages = false;
    includeEmulator = false;

    # Accepting more licenses declaratively:
    extraLicenses = [
      # Already accepted for you with the global accept_license = true or
      # licenseAccepted = true on androidenv.
      # "android-sdk-license"

      # These aren't, but are useful for more uncommon setups.
      "android-sdk-preview-license"
      "android-googletv-license"
      "android-sdk-arm-dbt-license"
      "google-gdk-license"
      "intel-android-extra-license"
      "intel-android-sysimage-license"
      "mips-android-sysimage-license"
    ];
  };

  androidComposition = androidEnv.composeAndroidPackages sdkArgs;
  androidSdk = androidComposition.androidsdk;
  platformTools = androidComposition.platform-tools;
  jdk = pkgs.jdk;
in
pkgs.mkShell rec {
  name = "androidenv-example-without-emulator-demo";
  packages = [ androidSdk platformTools jdk pkgs.android-studio ];

  LANG = "C.UTF-8";
  LC_ALL = "C.UTF-8";
  JAVA_HOME = jdk.home;

  # Note: ANDROID_HOME is deprecated. Use ANDROID_SDK_ROOT.
  ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";

  shellHook = ''
    # Write out local.properties for Android Studio.
    cat <<EOF > local.properties
    # This file was automatically generated by nix-shell.
    sdk.dir=$ANDROID_SDK_ROOT
    EOF
  '';

  passthru.tests = {

    shell-without-emulator-sdkmanager-packages-test = pkgs.runCommand "shell-without-emulator-sdkmanager-packages-test"
      {
        nativeBuildInputs = [ androidSdk jdk ];
      } ''
      output="$(sdkmanager --list)"
      installed_packages_section=$(echo "''${output%%Available Packages*}" | awk 'NR>4 {print $1}')
      echo "installed_packages_section: ''${installed_packages_section}"

      packages=(
        "build-tools;35.0.0" "cmdline-tools;13.0" \
        "patcher;v4" "platform-tools" "platforms;android-35"
      )

      for package in "''${packages[@]}"; do
        if [[ ! $installed_packages_section =~ "$package" ]]; then
          echo "$package package was not installed."
          exit 1
        fi
      done

      touch "$out"
    '';

    shell-without-emulator-sdkmanager-excluded-packages-test = pkgs.runCommand "shell-without-emulator-sdkmanager-excluded-packages-test"
      {
        nativeBuildInputs = [ androidSdk jdk ];
      } ''
      output="$(sdkmanager --list)"
      installed_packages_section=$(echo "''${output%%Available Packages*}" | awk 'NR>4 {print $1}')

      excluded_packages=(
        "emulator" "ndk"
      )

      for package in "''${excluded_packages[@]}"; do
        if [[ $installed_packages_section =~ "$package" ]]; then
          echo "$package package was installed, while it was excluded!"
          exit 1
        fi
      done

      touch "$out"
    '';
  };
}

