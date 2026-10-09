# The garden's pipeline - filter, renderer, serving config - as one function
# of the site's settings.
#
# Exported as the flake's `lib.mkGarden`. The service that runs the garden
# (dotfiles' `cg.service.digital-garden`) and `nix run .#garden-preview` both
# call this, which is what keeps the preview from drifting from the server:
# both are handed the same pieces built from the same settings (lib/site.nix),
# rather than the preview reading them back out of an evaluated host.
# The filter checks import lib/filter.nix directly: it takes no settings, so
# it is the same derivation either way.
#
# `pkgs` is the caller's, and everything here is built from it: a host builds
# its garden with its own Hugo and Python, and this repository's flake.lock
# governs only its own checks and preview. checks/consumer-pkgs.nix holds the
# pipeline to that.
{
  pkgs,
  baseUrl,
  siteTitle,
  siteDescription,
  styleSheet,
  footerLinks,
}:
let
  inherit (pkgs) lib;
in
{
  renderer = (import ./hugo.nix { inherit pkgs lib; }).mkRenderer {
    inherit
      baseUrl
      siteTitle
      siteDescription
      styleSheet
      footerLinks
      ;
  };
  # The publish filter: publish-filter.py and the bonsai.py it imports,
  # assembled into one directory. See the header of lib/filter.nix.
  filter = import ./filter.nix { inherit pkgs; };
  serve = import ./serve.nix { inherit lib; };
  # The rendering fixture: every element the theme styles, on as few pages
  # as possible. See the header of lib/preview.nix.
  fixture = ./hugo/fixture;
  # The stylesheet baked into the renderer, for a caller that wants to
  # offer a different one in its place.
  inherit styleSheet;
}
