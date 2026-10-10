# Plan: a test seam for the digital garden

The garden's Python has no tests of its own beyond the shelf-collision refusal and the fixture's page count. Almost every assertion about what it publishes is made through dotfiles' VM check, which boots a machine, builds the site and greps the served HTML. Most of that is a pure function of (fixture vault) -> (staging tree, rendered site). This plan moves those assertions to where they can be tested as one, and makes the small structural changes that let it.

The suite below is the precondition [ADR 0002](../adr/0002-the-filter-and-the-bonsai-stay-in-python.md) sets on reopening a rewrite.

Issues are still in `corygyarmathy/dotfiles` until they are transferred here; GitHub redirects the links below when they move. The fail-closed guard that refuses a staged note without the marker is in dotfiles' module, not here, so items 5 and 9 each need a dotfiles change as well.

| #   | Item                                              | Size   | Depends on | Status                                                                                         |
| --- | ------------------------------------------------- | ------ | ---------- | ---------------------------------------------------------------------------------------------- |
| 1   | One fixture, shared by the preview and the checks | small  | -          | open ([dotfiles#299](https://github.com/corygyarmathy/dotfiles/issues/299))                    |
| 2   | Lift the pipeline out of the host evaluation      | -      | -          | done ([dotfiles#377](https://github.com/corygyarmathy/dotfiles/pull/377))                      |
| 3   | One dotfile rule, one spelling                    | -      | -          | done ([dotfiles#313](https://github.com/corygyarmathy/dotfiles/pull/313))                      |
| 4   | Golden: staging tree and rendered HTML            | medium | 1          | open ([dotfiles#302](https://github.com/corygyarmathy/dotfiles/issues/302))                    |
| 5   | Refusals and determinism, asserted explicitly     | small  | 1          | open ([dotfiles#303](https://github.com/corygyarmathy/dotfiles/issues/303)), guard in dotfiles |
| 6   | Shrink the VM check to what a VM is for           | medium | 4, 5       | open ([dotfiles#304](https://github.com/corygyarmathy/dotfiles/issues/304)), stays in dotfiles |
| 7   | `filter_vault(...) -> Report`, and pass 5 split   | medium | 4, 5       | open ([dotfiles#305](https://github.com/corygyarmathy/dotfiles/issues/305))                    |
| 8   | Stage names and the hue ring, declared once       | small  | 4          | open ([dotfiles#306](https://github.com/corygyarmathy/dotfiles/issues/306))                    |
| 9   | One publish marker, matched the same way twice    | small  | 5          | open ([dotfiles#307](https://github.com/corygyarmathy/dotfiles/issues/307)), guard in dotfiles |

Order matters in one place: the golden lands before the Python is touched, so that the cleanup in item 7 can be shown not to change what gets published. Item 6 lands after the golden has run green against at least one real change, not in the same pull request - deleting the old coverage in the commit that adds its replacement means the first evidence the replacement works is also the moment the old one is gone.

## 1. One fixture

There are two adversarial vaults with overlapping jobs and no knowledge of each other: `lib/hugo/fixture/` here (every element the theme styles, plus the landing page and the only attachment anywhere) and roughly 290 inline lines in dotfiles' `checks/digital-garden.nix`. Neither covers both jobs, and the consequence is that attachments and the landing-page special case are asserted by nothing: the `render` check builds the fixture, but only counts its pages.

Merge into the preview fixture, so `garden-preview --fixture` renders exactly what the checks assert on. The private notes are safe to keep there: the preview applies the publish boundary exactly as the server does.

## 4. Golden

Staging tree and rendered HTML, blessed the way the palette is - `assertGenerated` plus an app that re-writes the copies. The stylesheet's fingerprinted href is normalised so a CSS edit does not churn it; the stylesheet itself stays on the screenshot loop, which is how visual change is judged here.

## 5. Refusals and determinism

What a golden cannot express: the URL-collision exit, the unparseable-note skip, the fail-closed guard refusing a staged note without the marker, and two consecutive runs producing byte-identical output - the property the skip gates rest on and which nothing currently checks. The guard is in dotfiles' module (`modules/services/digital-garden/digital-garden.nix`), so its refusal is asserted there, or the guard moves into the pipeline first.

## 6. Shrink the VM check

The VM check stays in dotfiles with the module it boots, so this item is worked there, in [dotfiles#304](https://github.com/corygyarmathy/dotfiles/issues/304), once items 4 and 5 have landed here.

## 7. `filter_vault` and pass 5

Bounded deliberately. `main` becomes argv parsing and an exit code; the work moves behind an entry point that returns a result rather than printing and exiting. Pass 5 is most of `main` and does three jobs - derive dates, write the flat tree, swap it in - which become three. Passes 1 to 4 are left alone; the golden pins them.

## 8. Stage names and the hue ring

The three maturity stage names appear in ten places and the ring size in three, one of which is a test asserting `range(8)`. Both are constants; Nix already generates `hugo.toml` and can feed the filter and the templates from one definition. The wider frontmatter contract waits - the golden will show which keys are dead (`word_count` and `maturity_score` are written and read by nobody) and those get deleted before anything is declared.

## 9. One publish marker

The filter matches the marker case-insensitively; the guard that backs it, in dotfiles' module, re-spells the same rule as an ERE without the flag. A note written `Publish: TRUE` is therefore staged and then refuses the entire build. Both become case-sensitive - `publish: true` is the documented spelling and what Obsidian's property editor writes, and an exact marker is what a publish boundary should use - and a check asserts the two agree. Changing the guard is a dotfiles pull request, unless the guard has moved into the pipeline by then.
