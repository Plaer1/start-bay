# Upstream provenance

Pinned upstream revisions the build uses. The inputs are copied unchanged into [`sources/upstream/`](../sources/upstream/), each with its licence text and a `PIN` file holding the revision. The build reads only those copies.

`sources/derived/comic-neue/` holds Medium and SemiBold instances cut from Comic Neue's own sources by `scripts/make_neue_weights.py`. They are Modified Versions under OFL-1.1 and carry no Reserved Font Name.

Comic Mono is listed for its monospacing approach only: no code or outlines from it are in the build.

| Upstream | Revision (commit date) | License | Copyright |
|---|---|---|---|
| [Comic Neue](https://github.com/crozynski/comicneue) | `ef5be72411141d01f0b865df8edb47e552c11c3c` (2020-11-11) | OFL-1.1, no Reserved Font Name; [text](ComicNeue-OFL.txt) | 2014 The Comic Neue Project Authors |
| [Comic Mono](https://github.com/dtinth/comic-mono-font) | `13eb162648d01d61ece424088dbf750ec80a1a62` (2025-11-19) | MIT; [text](ComicMono-MIT.txt) | 2018 Shannon Miwa (original work, Comic Shanns v1); 2019 dtinth (modified work) |
| [Fira Code](https://github.com/tonsky/FiraCode) | `ecd367b040ad92a28b64fa93135775f7e2417b37` (2026-07-28) | OFL-1.1, no Reserved Font Name; [text](FiraCode-OFL.txt) | 2014 The Fira Code Project Authors |
| [OpenDyslexic](https://opendyslexic.org) ([source](https://forge.hackers.town/antijingoist/opendyslexic)) | `48218028cc8bd9f4f244cd4ce4049e6c879d4d1a` (2025-11-29) | OFL-1.1, **Reserved Font Name "OpenDyslexic"**; [text](OpenDyslexic-OFL.txt) | 2012-2019 Abbie Gonzalez |

Lineage notes:

- Comic Mono is a patched fork of [Comic Shanns](https://github.com/shannpersand/comic-shanns) v1 by Shannon Miwa, with metrics based on Cousine.
- OpenDyslexic's canonical source is the hackers.town forge, which opendyslexic.org links. The GitHub repo is an older mirror.
- No Modified Version may use the Reserved Font Name "OpenDyslexic" as its name.
- OFL-1.1 requires fonts derived from Comic Neue, Fira Code or OpenDyslexic to stay under OFL-1.1. The MIT notice for Comic Mono must be kept with any derived copy.
