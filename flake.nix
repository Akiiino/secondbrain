{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem = {
        pkgs,
        self',
        ...
      }: {
        formatter = pkgs.alejandra;
        devShells.default = import "${self}/devshell.nix" {inherit self pkgs inputs;};

        packages = {
            CTO = pkgs.writers.writePython3Bin "CTO" {
                libraries = with pkgs.python3Packages; [caldav];
            } (builtins.readFile "${self}/packages/CTO.py");
            talos = pkgs.writers.writePython3Bin "talos" {
                libraries = with pkgs.python3Packages; [python-telegram-bot flask apscheduler uvicorn starlette];
            } (builtins.readFile "${self}/packages/talos.py");
        };
      };
      flake = {
        nixosModules = {
            CTO = import "${self}/modules/CTO.nix" self;
            talos = import "${self}/modules/talos.nix" self;
        };
      };
    };
}
