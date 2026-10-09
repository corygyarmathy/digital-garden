# ADR 0002: The filter and the bonsai stay in Python

- **Status:** Accepted
- **Date:** 2026-10-09
- **Related Artefacts:**
    - Carried from: §2 and §3 of `corygyarmathy/dotfiles` [ADR 0009](https://github.com/corygyarmathy/dotfiles/blob/d79147ca86fd10f7043c0e8d38e739e34004ba5f/docs/adr/0009-the-garden-stays-in-this-repository-and-in-python.md), which was closed unmerged in [dotfiles#297](https://github.com/corygyarmathy/dotfiles/pull/297). [ADR 0001](0001-the-garden-lives-in-its-own-repository.md) replaced its repository decision. This decision is unchanged, and is recorded here so the reasoning moved with the garden.
    - Implemented by: the test seam named in §2 below

## Context

`publish-filter.py` and `bonsai.py` are two Python programs, roughly 2,500 lines together, in a repository that is otherwise Nix, Hugo templates and CSS. Someone proposed rewriting them in Go, on the general argument that Python past a few hundred lines resists organisation and testing. The filter is the publish boundary, the code that stands between a private note and a public URL. That makes it the part of the garden whose failure is public and cannot be undone, and the part where a rewrite carries the most risk.

## Decision

**1. The filter and the bonsai stay in Python.** Testability is not a reason to rewrite them, because the test suite that makes them safe does not depend on the language: a fixture vault goes in, and a staging tree and rendered HTML come out. That suite is worth building whatever the filter is written in, and changing the language first does not make it easier to build.

Nor is the disorganisation a property of Python. Most of `publish-filter.py` is small pure functions that are fine. The hard-to-read part is one long `main` holding five passes, the fifth of which does three jobs. That shape would carry into a rewrite in any language unless someone fixes it deliberately, so it is worth fixing on its own terms first.

**2. A rewrite is reopened only behind a characterisation suite, and in a stated order.** Both conditions exist to stop a rewrite from being the thing that breaks the publish boundary:

- The golden test must exist and pass first, so both implementations can be held to the same output for the same vault. A rewrite of a fail-closed security boundary with nothing to catch a regression is how a private note reaches a public URL.
- If either program is rewritten, `bonsai.py` goes first. It is pure computation with deterministic seeding, no I/O and a single entry point: the easiest thing to port, and the one whose failure is cosmetic. `publish-filter.py` is the publish boundary, and it goes last or not at all.

If Go is reconsidered, its strongest argument is architectural rather than ergonomic. Hugo is itself written in Go, so a Go filter opens the possibility of collapsing the filter and the renderer into one program, vault in and site out. That would be a materially deeper module than today's two-program pipeline. The argument should be made on its own merits once the seams are in place, not as a side effect of disliking a long Python file.

## Consequences

**Positive**

- The work a rewrite would need first is worth doing whether or not the rewrite happens: a named entry point for the filter, one fixture, and a test suite that does not boot a machine.
- A future review gets the reasoning as well as the conclusion, and can tell whether the conditions in §2 have been met.

**Negative**

- Two Python programs stay in a repository that is otherwise Nix and templates, and the reader has to know that this is deliberate.
- The filter-and-renderer collapse that Go would allow stays out of reach until the suite exists.

## Alternatives considered

- **Rewrite `publish-filter.py` in Go first, and treat the rewrite as the cleanup.** Rejected, because it changes the publish boundary with nothing to check the new version against. The filter's stated rules (publish defaults to false, and an unparseable note is skipped rather than published) are fail-closed claims, and at most they are checked end to end, through dotfiles' VM check. A reimplementation would be judged by reading it, which is the weakest verification available, and it would be used for exactly the property whose failure is public and cannot be undone.
