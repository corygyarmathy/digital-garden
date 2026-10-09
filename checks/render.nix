# The fixture builds into a whole site: the filter stages it, the renderer
# renders it, and every staged note comes out the other end as a page.
#
# "It built" is weak evidence on its own. A template that does not parse is a
# Hugo error, but a *missing* or mis-wired one is not: Hugo skips the pages it
# would have rendered and reports success. The first Hugo build of this site
# emitted the home page and nothing else. So the assertions below count, and
# they count against the staging tree rather than against a list written here,
# so a note added to the fixture is covered without touching this file.
#
# This is the garden's own gate on the layouts, which prettier deliberately
# does not format (see treefmt.toml): a change that breaks the build fails
# here, before dotfiles' nightly lock bump ever sees it. It asserts that the
# site is whole, not what it looks like - the rendered HTML itself is for the
# golden test (corygyarmathy/dotfiles#302) to pin, and the stylesheet is judged
# by rendering it with `garden-preview --fixture`.
#
# Not a VM: nothing here is served. The fixture is a directory, not a git
# vault, so the filter's revision counter needs no git.
{
  pkgs,
  # The pipeline as lib/pipeline.nix builds it from lib/site.nix: the same
  # filter, renderer and fixture `garden-preview --fixture` runs.
  garden,
}:
let
  inherit (garden) filter renderer fixture;
  # The same rule the service ignores vault paths by. See lib/ignore.nix.
  ignore = import ../lib/ignore.nix;
  python = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);
in
pkgs.runCommand "check-render"
  {
    nativeBuildInputs = [
      python
      pkgs.jq
    ];
    inherit filter;
  }
  ''
    set -euo pipefail
    fail() { echo "FAIL: $*" >&2; exit 1; }

    # Hugo keeps a module cache under $HOME, which the sandbox does not have.
    export HOME="$PWD/home"
    mkdir -p "$HOME"

    staging="$PWD/content"
    site="$PWD/site"
    python3 "$filter/publish-filter.py" ${fixture} "$staging" "$PWD/dates.json" \
      '${ignore.relative}'
    ${pkgs.lib.getExe renderer} "$staging" "$site"

    # index.md is the home page; every other staged note is a page of its own,
    # served at its file name.
    notes=()
    for f in "$staging"/*.md; do
      stem=$(basename "$f" .md)
      [ "$stem" = index ] || notes+=("$stem")
    done
    [ "''${#notes[@]}" -gt 0 ] || fail "the filter staged no notes from the fixture"

    # data-pagefind-body is on the pages the page layouts render and on
    # nothing else, so it tells a rendered note from an alias's redirect stub.
    for page in index.html notes/index.html; do
      grep -q data-pagefind-body "$site/$page" || fail "/$page was not rendered"
    done
    for stem in "''${notes[@]}"; do
      page="$site/$stem/index.html"
      [ -f "$page" ] || fail "$stem.md was staged but /$stem/ was not rendered"
      grep -q data-pagefind-body "$page" || fail "/$stem/ is not a rendered note"
      grep -qF "href=\"/$stem/\"" "$site/notes/index.html" \
        || fail "/notes/ does not link /$stem/"
    done

    [ -f "$site/404.html" ] || fail "no 404 page"
    items=$(grep -c '<item>' "$site/index.xml") || fail "the feed has no items"
    [ "$items" -eq "''${#notes[@]}" ] \
      || fail "the feed has $items items for ''${#notes[@]} notes"

    # Fingerprinted, so its name is read off the page that links it.
    css=$(grep -o 'href="/main\.[0-9a-f]*\.css"' "$site/index.html" | head -1 | cut -d'"' -f2) \
      || fail "the home page links no stylesheet"
    [ -s "$site$css" ] || fail "the linked stylesheet $css is missing or empty"

    # Pagefind indexes the rendered HTML, so an index that covers fewer pages
    # than were rendered means the pages were not there when it ran.
    indexed=$(jq '[.languages[].page_count] | add' "$site/pagefind/pagefind-entry.json")
    [ "$indexed" -ge $(( ''${#notes[@]} + 2 )) ] \
      || fail "search covers $indexed pages; expected the notes, home and /notes/"

    touch "$out"
  ''
