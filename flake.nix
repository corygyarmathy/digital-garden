{
  description = "A digital garden: the public notes of a private Obsidian vault, published as a static site";

  # This lock governs this repository's own checks and preview, and nothing
  # else: `lib.mkGarden` builds from the `pkgs` its caller hands it.
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      # Linux only: the preview watches with inotify.
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # The site this repository's own preview renders. The domain is the
      # fleet's (see lib/site.nix), stated again here because a checkout of
      # this repository has no fleet to ask.
      site = self.lib.site { domain = "gyarmathy.co"; };

      gardenFor = pkgs: self.lib.mkGarden ({ inherit pkgs; } // site);
    in
    {
      lib = {
        # { pkgs, baseUrl, siteTitle, siteDescription, styleSheet, footerLinks }
        #   -> { renderer, filter, serve, fixture, styleSheet }
        mkGarden = import ./lib/pipeline.nix;
        # { domain } -> the settings above, minus `pkgs`.
        site = import ./lib/site.nix;
        # The vault-path ignore rule, in each consumer's dialect.
        ignore = import ./lib/ignore.nix;
      };

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          garden = gardenFor pkgs;
        in
        {
          inherit (garden) renderer filter;
          garden-preview = import ./lib/preview.nix {
            inherit pkgs garden;
            inherit (pkgs) lib;
          };
        }
      );

      # Local preview, re-rendering on save. See lib/preview.nix.
      #
      #   nix run .#garden-preview
      #   nix run .#garden-preview -- --fixture
      apps = forAllSystems (system: {
        garden-preview = {
          type = "app";
          program = nixpkgs.lib.getExe self.packages.${system}.garden-preview;
          meta.description = "Local preview that renders and serves the digital garden exactly as the server does";
        };
      });

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          filter = import ./checks/digital-garden-filter.nix { inherit pkgs; };
          ignore = import ./checks/digital-garden-ignore.nix { inherit pkgs; };
          consumer-pkgs = import ./checks/consumer-pkgs.nix {
            inherit pkgs site;
            inherit (self.lib) mkGarden;
          };
          render = import ./checks/render.nix {
            inherit pkgs;
            garden = gardenFor pkgs;
          };
          fmt-gate = import ./checks/fmt-gate.nix {
            inherit pkgs;
            formatter = self.formatter.${system};
          };
          # Building it runs shellcheck over the script, which is as close as
          # a check gets to the preview without a browser.
          inherit (self.packages.${system}) garden-preview;
        }
      );

      # `nix fmt` formats the tree; `nix fmt -- --ci` is the CI gate. What
      # runs on each file type is ./treefmt.toml; this wrapper only supplies
      # the binaries, from this flake's own nixpkgs so the versions deciding
      # the gate are the ones in flake.lock. The list must cover every
      # command treefmt.toml declares.
      formatter = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.writeShellApplication {
          name = "formatter";
          runtimeInputs = with pkgs; [
            black
            markdownlint-cli2
            nixfmt
            prettier
            taplo
            treefmt
          ];
          text = ''
            exec treefmt "$@"
          '';
        }
      );
    };
}
