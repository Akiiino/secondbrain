flake: {
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (flake.packages.${pkgs.stdenv.hostPlatform.system}) CTO;
  inherit (lib) filterAttrs types mkEnableOption mkOption mkRenamedOptionModule;

  cfg = config.services.secondbrain.CTO;
in {
  options.services.secondbrain.CTO = {
    enable = mkEnableOption ''
      Calendar Task Organizer: a tool for creating reocurring tasks automatically, based on calendar entries.
    '';

    calendarURL = mkOption {
      type = types.str;
      description = ''
        CalDAV URL for the calendar to use for reading events and creating tasks.
      '';
    };

    username = mkOption {
      type = types.str;
      description = ''
        Username for accessing the CalDAV server.
      '';
    };

    passwordFile = mkOption {
      type = types.path;
      description = ''
        File containing the password used for accesing the CalDAV server.
      '';
    };

    dayLookahead = mkOption {
      type = types.int;
      default = 1;
      description = ''
        How many days ahead to make tasks for.
      '';
    };

    time = {
      hour = mkOption {
        type = types.int;
        description = ''
          Hour when the calendar processing happens.
        '';
        default = 3;
      };
      minute = mkOption {
        type = types.int;
        description = ''
          Minute when the calendar processing happens.
        '';
        default = 0;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    users.users.CTO = {
      description = "secondbrain-CTO daemon user";
      isSystemUser = true;
      group = "CTO";
    };

    users.groups.CTO = {};

    systemd.services.CTO = {
      description = "secondbrain-CTO";

      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        User = "CTO";
        Group = "CTO";
        Type = "oneshot";
        ExecStart =
          "${CTO}/bin/CTO "
          + "--calendar ${cfg.calendarURL} "
          + "--user ${cfg.username} "
          + "--password-file ${cfg.passwordFile} "
          + "--day-lookahead ${builtins.toString cfg.dayLookahead}";
      };
    };
    systemd.timers.CTO = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "*-*-* ${builtins.toString cfg.time.hour}:${builtins.toString cfg.time.minute}:00";
        Persistent = "True";
        Unit = "CTO.service";
      };
    };
  };
}
