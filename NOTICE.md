# NOTICE

This repository packages and redistributes upstream software published by the
[fzf](https://junegunn.github.io/fzf/) project. The Apache-2.0 license in
[`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It does
**not** cover any upstream-derived asset — each package's redistributed bytes
carry their own license, recorded below.

Each package's logo is an original mark authored for this catalog; upstream
publishes only raster images and none are reproduced here. Any upstream name
used is used nominatively, for identification only. The marks remain the
property of their respective owners and no endorsement is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `fzf` | `ghcr.io/ocx-contrib/fzf/fzf` | `MIT` |

---

## `fzf`

Upstream: <https://github.com/junegunn/fzf>
Published to `ghcr.io/ocx-contrib/fzf/fzf`.

| Component | SPDX | Holder |
|---|---|---|
| fzf (`fzf`) | **MIT** | Copyright (c) 2013-2026 Junegunn Choi |

The MIT License is permissive and grants redistribution of the compiled binary
without restriction, subject to retaining the copyright notice and permission
notice. Those are reproduced above and the full license text is published
upstream at <https://github.com/junegunn/fzf/blob/master/LICENSE>. The
published binaries statically link third-party Go modules under permissive
licenses, enumerated in the `go.mod` / `go.sum` shipped in the upstream source
tree at the corresponding tag.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
