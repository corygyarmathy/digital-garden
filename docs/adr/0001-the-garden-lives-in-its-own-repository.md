# ADR 0001: The garden lives in its own repository

- **Status:** Accepted
- **Date:** 2026-10-09
- **Related Artefacts:**
    - Replaces: `corygyarmathy/dotfiles` [ADR 0009](https://github.com/corygyarmathy/dotfiles/blob/d79147ca86fd10f7043c0e8d38e739e34004ba5f/docs/adr/0009-the-garden-stays-in-this-repository-and-in-python.md), proposed in [dotfiles#297](https://github.com/corygyarmathy/dotfiles/pull/297) and closed unmerged. Its case for staying is the rejected alternative below. Its second decision, that the pipeline stays in Python, is carried over unchanged as [ADR 0002](0002-the-filter-and-the-bonsai-stay-in-python.md).
    - Specified by: [dotfiles#365](https://github.com/corygyarmathy/dotfiles/issues/365)
    - Consumed by: `cg.service.digital-garden` in `corygyarmathy/dotfiles`, the NixOS module that runs this pipeline on the fleet
    - Vocabulary: [`GLOSSARY.md`](../../GLOSSARY.md)

## Context

The digital garden grew up inside `corygyarmathy/dotfiles`, the fleet's NixOS configuration. Its pipeline (the publish filter, bonsai, the Hugo renderer, its templates and styling, the preview) changes far more often than the module that runs it, and for different reasons. Living there, it shared a tracker, a glossary and a review surface with the fleet, and the fleet bent around it: the garden's vocabulary was about to be added to the fleet's glossary, and its issues and reviews sat in the fleet's queue.

ADR 0009 argued for staying. It was written as a decision about where the seams are drawn, and it made three arguments against moving. All three are answered under Alternatives below.

## Decision

**1. The garden lives in its own repository, with its history.** `corygyarmathy/digital-garden` owns the pipeline, its tests, its plans, its ADRs and its vocabulary. Its history was carried over from dotfiles rather than imported as one commit, so `git log` and `git blame` still explain the code.

**2. Dotfiles keeps the module that runs the pipeline.** How the garden runs on the fleet is a fleet concern: the vault sync and its health signal, secrets, the reverse proxy and tunnel, alerts and the runbook. All of that stays in dotfiles, with the VM check that exercises it. This follows the precedent `afk-agent` set: the program lives in its own repository, and the module that deploys it stays with the fleet.

**3. The interface is one library function, and it takes the consumer's `pkgs`.** A consumer calls it with its own `pkgs` and the site's parameters, and gets back what it needs to build and serve the site; `flake.nix` names the function and what it returns. The consumer's toolchain builds the garden, so a lock bump here cannot change the Hugo or Python the fleet runs. This repository's own lock governs only its own checks and preview.

**4. A garden change deploys through dotfiles' existing lock bump.** No trigger runs from this repository into dotfiles, and no credential here can act on it. The nightly `flake-update` in dotfiles bumps this input along with the others, and its gate rebuilds the site from the new revision and asserts the publish boundary against it before anything is served.

## Consequences

**Positive**

- The garden has its own tracker, plans and glossary, and its own CI gate, none of whose checks boots a machine.
- The preview runs from a checkout of this repository, or from anywhere with `nix run github:corygyarmathy/digital-garden#garden-preview`, without evaluating a host.
- The publish boundary is asserted before a change goes live, by dotfiles' VM check during the lock bump. A change that leaks a private note fails there, and the deployed garden stays on the last good revision. This repository's own checks do not assert the boundary yet; the [test seam](../plans/garden-test-seam.md) adds that.

**Negative**

- A change merged here goes live the morning after, not on the night it merges, unless someone dispatches the lock bump by hand.
- Work that crosses the boundary needs two pull requests, and issues on each side refer to the other repository by full name.
- The VM check that asserts the served site stays in dotfiles, so this repository's CI cannot catch a regression that only shows up in a booted machine.
- The formatter configuration exists in three copies (dotfiles, `afk-agent`, here) until it is deduplicated.
- Older commit messages name paths that no longer exist.

## Alternatives considered

- **Stay in dotfiles (ADR 0009).** Rejected. Its three arguments, answered:
    - _The friction is internal, and a repository boundary moves it without dissolving it._ That is true of the friction it listed (untyped frontmatter, every assertion made through a VM), and it was never the reason to move. That friction is fixed inside the garden, by the test seam, in whichever repository the garden lives. The move is about ownership: the garden shared a tracker, a glossary and a review surface with the fleet, and none of those can be separated inside one repository. ADR 0009 listed one of them itself as a cost of staying (the garden's vocabulary landing in the fleet's glossary). The bend that could be fixed in place was fixed there: the preview stopped evaluating a host before the move ([dotfiles#377](https://github.com/corygyarmathy/dotfiles/pull/377)), so it is not part of this case.
    - _Extraction puts two landing hops on the loop that changes most._ This conflates the iteration loop with the deploy loop. The iteration loop is `garden-preview` against a working tree, and it moves here unchanged: it still re-renders on save, reading the stylesheet and fixture from the file being edited. The deploy loop does gain a hop, but no one has to take it: dotfiles' nightly `flake-update` already bumps every input and auto-merges when green, so a change merged here before that run is live the next morning with no added step. For a change that cannot wait, the same workflow can be dispatched by hand.
    - _The seams would be guessed during the move, which is where a wrong boundary costs most to redraw._ They were not. The interface was cut in dotfiles first ([dotfiles#300](https://github.com/corygyarmathy/dotfiles/issues/300)): `mkGarden` was built and proved against a host's closure diff, and then moved unchanged. The seams that do not exist yet (a golden test, a filter that returns a result) are inside the garden, not at its edge, and they are this repository's first work.
- **A two-layer module, with a fleet-agnostic NixOS module here wrapped by dotfiles.** Rejected. The wrapper's only job would be to forward values to the inner module, and what the module is about (`cg.fleet`, the reverse proxy, sops, monitoring) belongs to the fleet.
- **Consume the repository with `flake = false`, as dotfiles consumes `afk-agent`.** Rejected. The garden has checks and a preview app of its own, and `mkGarden` is a library function. It needs to be a real flake, with dotfiles' input following dotfiles' nixpkgs.
- **Trigger dotfiles from this repository with `repository_dispatch`.** Rejected. It needs a credential here that can act on dotfiles, and it only shortens a deploy latency nobody has asked to shorten.
