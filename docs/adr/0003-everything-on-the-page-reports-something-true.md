# ADR 0003: Everything on the page reports something true about the garden

- **Status:** Accepted
- **Date:** 2026-10-10
- **Related Artefacts:**
    - Applied by: `bonsai.py`, the growth marks (`lib/hugo/layouts/_partials/mark-icons.html`), the callout icons (`lib/hugo/layouts/_partials/callout-icons.html`) and the 404 page (`lib/hugo/layouts/404.html`)
    - Vocabulary: [`GLOSSARY.md`](../../GLOSSARY.md)

## Context

The site's first design was a neutral palette, a single column and a hand-written index, and the brief that started its redesign was that "the site is a little boring". Most answers to that brief add something to look at: a header image, generated artwork, a graph of the notes, typographic ornament. Each of them would be easy to add and hard to justify, and the brief alone does not say which kind of addition is wanted. Without a stated rule, the next proposal is judged on taste against whatever was accepted last.

## Decision

**Anything added to a page must report something true about the note or the garden it sits beside.** A maturity mark, a topic's hue, a section map drawn to scale, a callout icon naming the callout's type, and a tree whose every clump of foliage is a published note all pass. An addition with no referent does not, however good it looks.

The 404 page is the one exception, and it is confined there on purpose: a reader on a 404 has nothing to read, so the page can carry something that only looks alive. It is never on the home page, where it would compete with the bonsai.

## Consequences

**Positive**

- A proposal is judged by whether it has a referent before anyone argues about taste, which settles most of them quickly.
- What the site adds grows with the vault: the tree, the marks and the counts change as notes are written, and a fixed image would not.

**Negative**

- Each addition needs data the pipeline has to compute and carry (maturity, topic, section word counts), so a visual change often needs a filter change first.
- Ornament that would be cheap and harmless is turned down on principle.

## Alternatives considered

- **Stock photography.** Rejected. It is decoration with no referent: it says nothing about the note it sits beside.
- **Generated abstract artwork, such as a pattern derived from a hash of the note.** Rejected for the same reason. It looks like it carries meaning and does not, and it ages into a gimmick faster than a photograph does.
- **A graph view of the notes and their links.** Rejected. It does report something true, but what it reports is the link structure, and this vault has very few links between its notes, so the picture would be a handful of connected notes and a field of dots. It also needs a rendering library, which means a build-time fetch or a vendored framework in a site that ships none, and it works badly on a phone. The `/notes/` index and the backlinks answer "what else is near this" for much less. Worth reconsidering only if the link density grows with the vault. The bonsai is not a graph view: it draws the set of notes and their own properties, not the edges between them.
- **Bookish set pieces: drop caps, letterspaced small-caps openings, fleuron section breaks.** Rejected. They look right in a printed book and translate badly to a web page, and they report nothing. Callout icons are not in this class, because an icon that names a callout's type is information.
- **Build-time diagram languages (`d2`, `mermaid`).** Rejected. The vault's diagrams are draw.io exports, and a diagram language handles its own use case well and everything else, network diagrams especially, badly. A diagram that glares on the dark theme should be exported with a transparent ground instead.
