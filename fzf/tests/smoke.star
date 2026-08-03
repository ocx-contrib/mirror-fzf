# fzf/tests/smoke.star — stable across upstream fzf releases.
# Asserts the contract (exit code, version shape, computed match sets), never
# help/version prose. See ocx.mirror testing-practices.md.
#
# ⚠ fzf is an INTERACTIVE fuzzy finder. Invoked bare it opens the full-screen
# finder and waits for a keystroke, which would hang a CI leg until the job
# timeout — forever, from the runner's point of view. `--filter/-f` is the
# documented non-interactive mode ("do not start interactive finder"); every
# invocation below uses it, drives it from `stdin=` (no shell, no TTY, no
# temp files), and is verified to terminate with no controlling terminal.

FZF = "fzf.exe" if ocx.target_platform.os == ocx.os.Windows else "fzf"

# Tier 1 + 2: liveness on the composed PATH + version SHAPE (not the vendor
# banner, not the exact version — the digits are the contract).
r_version = ocx.run(FZF, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")


def lines(s):
    # `\r` tolerates a Windows console translating the line endings.
    return [l for l in s.replace("\r", "").split("\n") if l != ""]


# Hermetic input: six fixed candidates, generated here rather than read from
# the filesystem, so the match sets below are fully determined by fzf's
# algorithm and nothing else.
CANDIDATES = "alpha\nbravo\ncharlie\ndelta\necho\nfoxtrot\n"

# Tier 3a: the core contract — matching is FUZZY (subsequence), not substring.
# "ala" appears as a literal substring in NO candidate (`grep -c ala` over the
# same six lines returns 0), but it IS a subsequence of "alpha" (a·l·ph·a) and
# of nothing else here. So this reds against anything that degrades to a
# substring matcher, and against a truncated or wrong-arch archive that still
# happened to exec.
#
# Assert the result COUNT, never `expect.ok` alone: fzf exits 1 on "no match",
# so a broken filter that returned nothing would be caught by the count and
# missed by an exit-code check that tolerated it.
r_fuzzy = ocx.run(FZF, "--filter", "ala", stdin=CANDIDATES)
out_fuzzy = lines(r_fuzzy.stdout)
expect.eq(len(out_fuzzy), 1)
expect.eq(out_fuzzy[0], "alpha")

# Tier 3b: multi-match count AND ordering. `--no-sort` makes fzf a fuzzy grep
# that preserves input order, so the whole result list is deterministic and can
# be compared exactly. "o" is a subsequence of bravo, echo and foxtrot only.
r_multi = ocx.run(FZF, "--filter", "o", "--no-sort", stdin=CANDIDATES)
out_multi = lines(r_multi.stdout)
expect.eq(len(out_multi), 3)
expect.eq(out_multi, ["bravo", "echo", "foxtrot"])

# Tier 3c: the empty result is a real answer, not an error. Count is 0 and fzf
# signals it with a NON-zero exit — recording that here is what stops a future
# edit from "fixing" the assertions above with a blanket `expect.ok`.
r_none = ocx.run(FZF, "--filter", "zzzz", stdin=CANDIDATES)
expect.eq(len(lines(r_none.stdout)), 0)
expect.ne(r_none.exit_code, 0)

# No Tier 4: metadata.json declares PATH only (proven by Tier 1 liveness).
