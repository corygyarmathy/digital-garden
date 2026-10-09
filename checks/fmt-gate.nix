# The formatting gate rejects a dirty tree and accepts a clean one.
#
# Until this existed, the only evidence the gate worked was a green run - which
# looks identical whether the gate would have caught a dirty pull request or
# not. A later edit to treefmt.toml (an exclude glob that is too broad, a
# formatter dropped) or a treefmt bump that changes `--ci` would leave master
# green and the gate gating nothing.
#
# Ported from dotfiles' checks/fmt-gate.nix, alongside the configuration
# treefmt.toml copies from there, with its samples cut to the file types this
# repository has and its exclude cases re-pointed at the excludes here.
#
# Not a VM: what is under test is the exit behaviour of the formatter wrapper
# and the treefmt.toml it consumes. The Nix build sandbox has no nix daemon, so
# `nix fmt`'s resolution hop - evaluating this flake and execing the wrapper -
# is out of reach here; the `garden ci` job exercises it every run
# (`nix fmt -- --ci` on a real checkout). Everything from the wrapper onward is
# under test, by running the same `formatter` derivation `nix fmt` would exec,
# against scratch git repos carrying this repository's treefmt.toml and
# formatter configs.
#
# The clean expectations are not stored in the repository: they are produced
# by the pinned formatters inside the check, so they cannot drift from
# flake.lock. The dirty samples are what every assertion pivots on: the gate
# must reject them, the write pass must change them, and the gate must then
# accept its own output.
{
  pkgs,
  # The wrapper `nix fmt` execs: this flake's `formatter` for this system.
  formatter,
}:
pkgs.runCommand "check-fmt-gate" { nativeBuildInputs = [ pkgs.git ]; } ''
  set -eu

  fail() { echo "FAIL: fmt-gate: $*" >&2; exit 1; }
  assert_rc() { # assert_rc <0|ne0> <label> <cmd...>
    want=$1; label=$2; shift 2
    log="$PWD/last.log"
    set +e
    "$@" >"$log" 2>&1
    rc=$?
    set -e
    if [ "$want" = 0 ] && [ "$rc" -ne 0 ]; then
      echo "--- $label: exited $rc, expected 0" >&2
      cat "$log" >&2
      fail "$label exited $rc, expected 0"
    elif [ "$want" = ne0 ] && [ "$rc" = 0 ]; then
      fail "$label exited 0, expected failure"
    fi
  }

  # treefmt writes its cache outside the tree unless told otherwise; keep
  # everything sandbox-local. `orig` and the caches live outside the scratch
  # repos: anything inside one is walked and formatted.
  export HOME="$PWD/home"
  export XDG_CACHE_HOME="$PWD/cache"
  export XDG_CONFIG_HOME="$PWD/config"
  mkdir -p "$HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"

  ############################################################
  # Scratch repo: this repository's formatting config, dirty
  # samples of every file type the pipeline claims to cover,
  # and a file each exclude claims to cover.
  ############################################################
  repo="$PWD/repo"
  orig="$PWD/orig"
  buildroot="$PWD"
  mkdir "$repo" "$orig"
  cp ${../treefmt.toml} "$repo/treefmt.toml"
  cp ${../.prettierrc.yaml} "$repo/.prettierrc.yaml"
  cp ${../.markdownlint-cli2.yaml} "$repo/.markdownlint-cli2.yaml"
  chmod u+w "$repo"/*.toml "$repo"/.*.yaml
  cd "$repo"
  git init -q
  git config user.email check@example.com
  git config user.name fmt-gate

  printf 'x=1\n\ndef  f( a, b ) :\n    return a+b\n' > dirty.py
  printf '{\n  a = 1;b = 2;\n}\n' > dirty.nix
  printf '#  Heading\n\n\nsome  text\n\n- a\n  - b\n' > dirty.md
  printf 'a   =  1\n[table]\nb="x"\n' > dirty.toml
  printf 'key:   "value"\nlist:\n    -  a\n' > dirty.yaml
  printf 'a{color:red;margin:0}\n' > dirty.css

  # Go templates are excluded from prettier: the gate must leave them alone.
  mkdir -p lib/hugo/layouts
  printf '<p   class="x">{{ .Title }}</p   >\n<a href="{{ .Permalink }}">x</a>\n' \
    > lib/hugo/layouts/dirty.html

  # The rendering fixture is excluded from markdownlint: adjacent callouts
  # must stay separate blockquotes, which MD028 forbids and cannot fix. The
  # gate must accept it there, and reject the same file anywhere else.
  mkdir -p lib/hugo/fixture
  printf '# Fixture\n\n> [!note]\n> One.\n\n> [!tip]\n> Two.\n' > lib/hugo/fixture/md028.md

  for f in dirty.py dirty.nix dirty.md dirty.toml dirty.yaml dirty.css \
    lib/hugo/layouts/dirty.html lib/hugo/fixture/md028.md; do
    mkdir -p "$orig/$(dirname "$f")"
    cp "$f" "$orig/$f"
  done
  git add -A

  # A tree that is dirty under the pipeline must fail the gate - the whole
  # point of `--ci`. (--ci formats in place and then fails on the change,
  # which the next two assertions lean on.)
  assert_rc ne0 "gate on dirty tree" ${formatter}/bin/formatter --ci

  # Every dirty sample was changed, and the excluded files were not.
  for f in dirty.py dirty.nix dirty.md dirty.toml dirty.yaml dirty.css; do
    cmp -s "$f" "$orig/$f" && fail "$f was not reformatted under --ci"
  done
  cmp -s lib/hugo/layouts/dirty.html "$orig/lib/hugo/layouts/dirty.html" \
    || fail "lib/hugo/layouts/ was reformatted despite the exclude"
  cmp -s lib/hugo/fixture/md028.md "$orig/lib/hugo/fixture/md028.md" \
    || fail "lib/hugo/fixture/ was rewritten"

  # Write mode on the now-clean tree is a no-op that exits 0, and the gate
  # accepts its own output - with both excluded files still in the tree.
  assert_rc 0 "write mode on clean tree" ${formatter}/bin/formatter
  assert_rc 0 "gate on formatted tree" ${formatter}/bin/formatter --ci

  # Each file type re-dirtied on its own must fail the gate on its own. (The
  # tree was proven clean one assertion ago, so each failure is attributable
  # to the file just re-dirtied.)
  while IFS= read -r f; do
    cp "$orig/$f" "$f"
    assert_rc ne0 "gate on re-dirtied $f" ${formatter}/bin/formatter --ci
    ${formatter}/bin/formatter >/dev/null 2>&1 # clean up for the next iteration
  done <<'EOF'
  dirty.py
  dirty.nix
  dirty.md
  dirty.toml
  dirty.yaml
  dirty.css
  EOF

  # The fixture's MD028 outside the fixture is a failure the write pass cannot
  # fix: what proves the fixture's exclude is the exclude, not a lenient rule.
  cp "$orig/lib/hugo/fixture/md028.md" md028.md
  assert_rc ne0 "gate on MD028 outside the fixture" ${formatter}/bin/formatter --ci
  rm md028.md

  ############################################################
  # A formatter declared without its binary must be a hard
  # error, not a silent skip - that is what keeps the
  # runtimeInputs list in flake.nix honest against
  # treefmt.toml.
  ############################################################
  repo2="$buildroot/repo2"
  mkdir "$repo2"
  cp ${../treefmt.toml} "$repo2/treefmt.toml"
  # cp preserves the store path's read-only mode; the append below needs write.
  chmod u+w "$repo2/treefmt.toml"
  printf '\n[formatter.not-a-real-formatter]\ncommand = "not-a-real-formatter"\nincludes = ["*.txt"]\n' >> "$repo2/treefmt.toml"
  cd "$repo2"
  git init -q
  git add -A
  assert_rc ne0 "declared formatter without a binary" ${formatter}/bin/formatter

  touch "$out"
''
