# mirror-fzf

OCX mirror for [fzf](https://junegunn.github.io/fzf/), a command-line fuzzy
finder. One repository, one spec directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [fzf](https://github.com/junegunn/fzf) | [`fzf/mirror.yml`](fzf/mirror.yml) | `ghcr.io/ocx-contrib/fzf/fzf` | [`ocx.sh/fzf/fzf`](https://index.ocx.sh/fzf/fzf) | `MIT` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

`junegunn` is a personal handle rather than a vendor, so the tool names itself:
`fzf/fzf`.

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
fzf/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. Restate a block in full or
not at all. `fzf/mirror.yml` does not restate it.

## Platforms

`fzf` publishes six platform entries: both Linux arches, both macOS arches and
both Windows arches. Asset names use **Go**-style os/arch tokens
(`linux_amd64`, `darwin_arm64`) rather than Rust target triples, and the
version in the filename carries no `v` even though the tag does
(`v0.74.2` → `fzf-0.74.2-linux_amd64.tar.gz`).

There is **no gnu/musl split** — upstream ships one Linux binary per arch — but
that was measured, not assumed: a Go binary built with cgo enabled *is*
dynamically linked and would need `+libc.glibc`. Both Linux binaries were
byte-measured on `v0.74.2` and on the `v0.74.0` floor and are fully **static**:
no `PT_INTERP`, no `DT_NEEDED`, `ldd` reports *not a dynamic executable*.
`os.features` states what an artifact requires *of the host*, so both Linux
keys are **bare**: a `+libc.*` suffix would be a false requirement that hid the
package from hosts it in fact runs on. The `alpine:3.20` container leg in
`mirror-base.yml` is what turns that claim into evidence; the measurement
itself is recorded above the `assets:` block in `fzf/mirror.yml`.

Upstream additionally ships `linux_armv5/armv6/armv7`, `linux_riscv64`,
`linux_ppc64le`, `linux_s390x`, `linux_loong64`, `freebsd_amd64`,
`openbsd_amd64` and `android_arm64`. None of those has an OCX platform key, so
they are deliberately out of scope. From `v0.74.1` upstream also attaches nine
`.deb` packages; those are distro packaging, not portable archives, and the
anchored `^…$` asset patterns exclude them. The tar.gz/zip platform set is
identical across the whole `0.74.0`–`0.74.2` range, so no floor bump and no
per-platform `min_version` are needed.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `fzf/mirror.yml` | hand | yes — see below |
| `fzf/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `fzf/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec fzf/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## The binaries claim

`fzf/metadata.json` declares `binaries: ["fzf"]` by hand, and `fzf/mirror.yml`
sets `bin_scan: "off"` — forced, not preferred. The scan only inspects an
interface-visible `${installPath}/<dir>` PATH entry, and fzf's archives are
**flat**: a single `fzf` (`fzf.exe` on Windows) sits at the archive root with
no subdirectory to point one at. With nothing to inspect the scan would pass
green whatever the archive contained, so `auto` and `verify` both fail spec
load at exit 65 rather than offer a hollow check. The hand-written list is what
the error message itself directs, and it is as short as a list gets — `fzf` is
the only member of the archive.

## The smoke test

fzf is an **interactive** finder: invoked bare it opens a full-screen TUI and
waits for a keystroke, which would hang a CI leg until the job timeout. The
smoke test drives it exclusively through `--filter`, the documented
non-interactive mode, feeding candidates via `stdin=` — no shell, no TTY, no
temp files. It asserts the result **count** and the exact match list rather
than an exit code, because fzf reports "no match" with a non-zero exit and an
empty result is a legitimate answer. The discriminating assertion is that
`--filter ala` returns exactly `alpha`: `ala` is a literal substring of no
candidate, so anything that degraded to substring matching would return zero.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; each
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
