{
  description = "GitHub CLI extension to show contribution graph";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ self, flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, system, ... }:
        let
          gh-graph = pkgs.stdenv.mkDerivation {
            pname = "gh-graph";
            version = if self ? shortRev then self.shortRev else "dev";

            src = self;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            installPhase = ''
              runHook preInstall
              install -Dm755 gh-graph $out/bin/gh-graph
              wrapProgram $out/bin/gh-graph \
                --prefix PATH : ${
                  pkgs.lib.makeBinPath [
                    pkgs.curl
                    pkgs.gh
                  ]
                }
              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "GitHub CLI extension to show contribution graph";
              homepage = "https://github.com/kawarimidoll/gh-graph";
              license = licenses.mit;
              maintainers = [ ];
              mainProgram = "gh-graph";
            };
          };
        in
        {
          packages = {
            inherit gh-graph;
            default = gh-graph;
          };
        };

      flake = {
        overlays.default = _final: prev: {
          gh-graph = self.packages.${prev.system}.default;
        };

        homeManagerModules.default =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          let
            cfg = config.programs.gh-graph;
          in
          {
            options.programs.gh-graph = {
              enable = lib.mkEnableOption "gh-graph - GitHub CLI extension to show contribution graph";

              package = lib.mkOption {
                type = lib.types.package;
                default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
                description = "The gh-graph package to use.";
              };
            };

            config = lib.mkIf cfg.enable {
              home.packages = [ cfg.package ];
            };
          };
      };
    };
}
