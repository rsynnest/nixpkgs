{ config, pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./nixos/modules/services/video/unifi-video.nix
  ];

  services.unifi-video = {
    enable = true;



    # Use the last known working mongodb package.
    # https://github.com/NixOS/nixpkgs/issues/75133
   # mongodbPackage = let
   #   channelRelease = "nixos-19.09pre190687.3f4144c30a6";  # last known working mongo
   #   channelName = "unstable";
   #   url = "https://releases.nixos.org/nixos/${channelName}/${channelRelease}/nixexprs.tar.xz";
   #   sha256 = "040f16afph387s0a4cc476q3j0z8ik2p5bjyg9w2kkahss1d0pzm";

   #   pinnedNixpkgsFile = builtins.fetchTarball {
   #     inherit url sha256;
   #   };

   #   pinnedNixpkgs = import pinnedNixpkgsFile {};
   # in pinnedNixpkgs.mongodb;

  };

  networking.firewall.enable = false;
  #networking.firewall.allowedTCPPorts = [ 8443 ];
  services.unifi = {
    enable = true;
    jrePackage = pkgs.jre8_headless;
    unifiPackage = pkgs.unifiStable;

    # Use the last known working mongodb package.
    # https://github.com/NixOS/nixpkgs/issues/75133
    mongodbPackage = let
      channelRelease = "nixos-19.09pre190687.3f4144c30a6";  # last known working mongo
      channelName = "unstable";
      url = "https://releases.nixos.org/nixos/${channelName}/${channelRelease}/nixexprs.tar.xz";
      sha256 = "040f16afph387s0a4cc476q3j0z8ik2p5bjyg9w2kkahss1d0pzm";

      pinnedNixpkgsFile = builtins.fetchTarball {
        inherit url sha256;
      };

      pinnedNixpkgs = import pinnedNixpkgsFile {};
    in pinnedNixpkgs.mongodb;
  };


  services.sshd.enable = true;


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.rsynnest = {
    isNormalUser = true;
    home = "/home/rsynnest";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "data" # Provide access to data folders
      "docker" # Access to docker socket
      "libvirtd" # access to qemu
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKzRwyLCm+Fp4yulEB0cyeElAsb7VknxuBYTlAuPc/3F rsynnest@nixos"
    ];
  }; 
  users.users.rsynnest.initialPassword = "butter1212";
}
