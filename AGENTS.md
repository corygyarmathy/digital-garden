# Agent instructions

The digital garden: the pipeline that turns an Obsidian vault into the published website. `publish-filter.py` builds the staging tree from the vault, `bonsai.py` grows the home page's tree, and Hugo renders the site. The flake exports `lib.mkGarden`, which [`corygyarmathy/dotfiles`](https://github.com/corygyarmathy/dotfiles) consumes as a flake input; its NixOS module, `cg.service.digital-garden`, runs the pipeline on the fleet ([ADR 0001](docs/adr/0001-the-garden-lives-in-its-own-repository.md)).

## Where things are

- [`GLOSSARY.md`](GLOSSARY.md) - the vocabulary.
- [`docs/adr/`](docs/adr/) - the decisions, and the reasoning behind them.
- [`docs/plans/`](docs/plans/) - the work in flight.
- [`checks/`](checks/) - the flake's checks; `lib/hugo/fixture/` is the vault they and the preview render.

Read what the work needs. None of it is required reading.

## Formatting

`nix fmt` (treefmt with `treefmt.toml`) is the formatter of record, and CI gates on `nix fmt -- --ci`. Run `nix fmt` once from the repository root before finishing, whatever you touched. Files in the `excludes` of `treefmt.toml` are deliberately outside the pipeline; leave them alone rather than formatting them by hand.

## Checks

```bash
nix fmt -- --ci
nix flake check --print-build-logs
```

These are the gate on master, in [`.github/workflows/ci.yml`](.github/workflows/ci.yml). Run them locally rather than waiting for CI.

A merge to master reaches production with no further human step: dotfiles' nightly flake update picks up the new revision. Treat the gate accordingly - add or update a check when you change what the pipeline publishes or refuses.

A visual change is not proven by reading templates or CSS. Render it: `nix run .#garden-preview -- --fixture` serves the fixture from this working tree and re-renders on save.

## Not here

The module, the vault sync, the fail-closed guard on the served tree, the VM check and the alerts live in dotfiles. A change that needs one of them is a dotfiles PR as well, and a ticket for one is filed there.

## Agent skills

### Issue tracker

Issues live in this repo's GitHub Issues (via the `gh` CLI). See [`docs/agents/issue-tracker.md`](docs/agents/issue-tracker.md).

### Triage labels

Six canonical roles map 1:1 to the tracker's label strings; nothing watches `ready-for-agent` unattended here. When triaging, including deciding between `ready-for-agent` and `ready-for-human`, see [`docs/agents/triage-labels.md`](docs/agents/triage-labels.md).

### Domain docs

Single-context: one `GLOSSARY.md` + `docs/adr/` at the repo root. See [`docs/agents/domain.md`](docs/agents/domain.md).

### Documentation

Which document owns a given fact (issue, ADR, plan, findings note, PR, commit, README, code comment), and when a plan entry gets deleted rather than kept for reference. Read before writing a plan, an ADR, or anything that might restate a fact another document already owns. See [`docs/agents/documentation.md`](docs/agents/documentation.md).
