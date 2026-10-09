# `lib.mkGarden` builds from the `pkgs` it is handed, not from this
# repository's flake.lock.
#
# The property matters to the fleet, not to this repository: a host builds its
# garden with its own toolchain, so a lock bump here cannot change the Hugo
# the fleet runs. It breaks silently - one `import nixpkgs` or one
# `inputs.nixpkgs.legacyPackages` inside the pipeline and every consumer gets
# this lock's Hugo, with nothing failing anywhere.
#
# A real second nixpkgs would make the check obvious and cost every consumer a
# second nixpkgs in their own lock, so the consumer's `pkgs` is this one with
# Hugo swapped for a stub instead. The renderer is then built from it, and the
# assertion is that the stub, and not this lock's Hugo, is in its closure.
{
  pkgs,
  mkGarden,
  site,
}:
let
  hugo = pkgs.writeShellScriptBin "hugo" ''
    echo "stub Hugo from checks/consumer-pkgs.nix; not a renderer" >&2
    exit 1
  '';
  consumerPkgs = pkgs.extend (_: _: { inherit hugo; });
  garden = mkGarden ({ pkgs = consumerPkgs; } // site);
  # Named, not depended on: the check has no reason to fetch the real Hugo.
  lockHugo = builtins.unsafeDiscardStringContext pkgs.hugo.outPath;
in
pkgs.runCommand "check-consumer-pkgs"
  {
    closure = pkgs.closureInfo { rootPaths = [ garden.renderer ]; };
  }
  ''
    set -euo pipefail
    fail() { echo "FAIL: $*" >&2; exit 1; }
    grep -qxF ${hugo} "$closure/store-paths" \
      || fail "the renderer was not built with the consumer's Hugo (${hugo})"
    ! grep -qxF ${lockHugo} "$closure/store-paths" \
      || fail "the renderer's closure holds this lock's Hugo (${lockHugo})"
    touch "$out"
  ''
