# Digital garden

The published website and the pipeline that produces it. This glossary covers only terms whose meaning here is narrower than their ordinary use. [ADR 0001](docs/adr/0001-the-garden-lives-in-its-own-repository.md) records why the pipeline lives in this repository. The NixOS module that runs it on the fleet lives in [`corygyarmathy/dotfiles`](https://github.com/corygyarmathy/dotfiles), which does not own this language.

**Vault** - the Obsidian notes repository the garden reads. It is not this repository and not part of it: it arrives by clone or by sync, and nothing in it is authored here. "The vault" never means the rendered site.

**Staging tree** - the published notes, filtered out of the vault, that the renderer builds the site from. It is the interface between the two programs: everything the renderer knows about a note arrives in this tree, and nothing else crosses. A note's place in it does not depend on where the note sat in the vault.

**Publish boundary** - the rule that a note reaches the staging tree only if it carries the literal publish marker, and the code that enforces it. Fail-closed in both directions: an unmarked note is not published, and a staged note found without the marker stops the whole build rather than being served.

**Maturity** - a note's stage, one of three: seedling, sapling, evergreen. Computed from the note rather than declared, though a hand-written value in the note wins. Not a synonym for age; a long-untouched stub stays a seedling.

**Topic** - the shelf a note belongs to, taken from the folder it came from in the vault. **Hue** is the colour that topic is drawn in, taken from a fixed set rather than chosen per topic.

**Bonsai** - the ASCII tree on the home page, grown from the published set. Deterministic: the same set of notes always draws the same tree.
