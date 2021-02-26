{ config, lib, pkgs, utils, ... }:
with lib;
let
  cfg = config.services.unifi-video;
  stateDir = "/var/lib/unifi-video";
  mountPoints = [
    {
      what = "${cfg.unifiVideoPackage}/lib";
      where = "${stateDir}/lib";
    }
    {
      what = "${cfg.mongodbPackage}/bin";
      where = "${stateDir}/bin";
    }
    {
      what = "${cfg.dataDir}";
      where = "${stateDir}/data";
    }
  ];
  systemdMountPoints = map (m: "${utils.escapeSystemdPath m.where}.mount") mountPoints;
in
{

  options = {

    services.unifi-video.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether or not to enable the unifi-video service.
      '';
    };

    services.unifi-video.jrePackage = mkOption {
      type = types.package;
      default = pkgs.jre8;
      defaultText = "pkgs.jre8";
      description = ''
        The JRE package to use. Check the release notes to ensure it is supported.
      '';
    };

    services.unifi-video.unifiVideoPackage = mkOption {
      type = types.package;
      default = pkgs.unifi-video;
      defaultText = "pkgs.unifi-video";
      description = ''
        The unifi-video package to use.
      '';
    };

    services.unifi-video.mongodbPackage = mkOption {
      type = types.package;
      default = pkgs.mongodb;
      defaultText = "pkgs.mongodb";
      description = ''
        The mongodb package to use.
      '';
    };

    services.unifi-video.dataDir = mkOption {
      type = types.str;
      default = "${stateDir}/data";
      description = ''
        Where to store the database and other data.

        This directory will be bind-mounted to ${stateDir}/data as part of the service startup.
      '';
    };

    services.unifi-video.openPorts = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether or not to open the required ports on the firewall.
      '';
    };

    services.unifi-video.initialJavaHeapSize = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 1024;
      description = ''
        Set the initial heap size for the JVM in MB. If this option isn't set, the
        JVM will decide this value at runtime.
      '';
    };

    services.unifi-video.maximumJavaHeapSize = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 4096;
      description = ''
        Set the maximimum heap size for the JVM in MB. If this option isn't set, the
        JVM will decide this value at runtime.
      '';
    };

  };

  config = mkIf cfg.enable {

    users.users.unifi-video = {
      #uid = config.ids.uids.unifi-video;
      uid = 9999;
      description = "UniFi Video controller daemon user";
      home = "${stateDir}";
    };

    networking.firewall = mkIf cfg.openPorts {
      # https://help.ui.com/hc/en-us/articles/217875218-UniFi-Video-Ports-Used
      allowedTCPPorts = [
        7080 # HTTP portal
        7443 # HTTPS portal
        7445 # Video over HTTP (mobile app)
        7446 # Video over HTTPS (mobile app)
        7447 # RTSP via the controller
        7442 # Camera management from cameras to NVR over WAN
      ];
      allowedUDPPorts = [
        6666 # Inbound camera streams sent over WAN
      ];
    };

    # We must create the binary directories as bind mounts instead of symlinks
    # This is because the controller resolves all symlinks to absolute paths
    # to be used as the working directory.
    systemd.mounts = map ({ what, where }: {
        bindsTo = [ "unifi-video.service" ];
        partOf = [ "unifi-video.service" ];
        unitConfig.RequiresMountsFor = stateDir;
        options = "bind";
        what = what;
        where = where;
      }) mountPoints;

    systemd.tmpfiles.rules = [
      "d '${stateDir}' 0700 unifi-video - - -"
      "d '${stateDir}/data' 0700 unifi-video - - -"
      "d '${stateDir}/lib/unifi-video/webapps' 0700 unifi-video - - -"
    ];

    systemd.services.unifi-video = {
      description = "UniFi Video NVR daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ] ++ systemdMountPoints;
      partOf = systemdMountPoints;
      bindsTo = systemdMountPoints;
      unitConfig.RequiresMountsFor = stateDir;
      # This a HACK to fix missing dependencies of dynamic libs extracted from jars
      environment.LD_LIBRARY_PATH = with pkgs.stdenv; "${cc.cc.lib}/lib/unifi-video/lib";
      # Make sure package upgrades trigger a service restart
      restartTriggers = [ cfg.unifiVideoPackage cfg.mongodbPackage ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.unifiVideoPackage}/bin/unifi-video start";
        ExecStop = "${cfg.unifiVideoPackage}/bin/unifi-video stop";
        Restart = "on-failure";
        User = "unifi-video";
        UMask = "0077";
        WorkingDirectory = "${stateDir}";
      };
    };

  };

  meta.maintainers = with lib.maintainers; [ rsynnest ];
}
