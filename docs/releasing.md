# Releasing

cig-orchestrator follows semantic versioning and the same release discipline
as CigScript: every version is a tag `vX.Y.Z` on main, every tag is a GitHub
release with one tarball, its checksum and a build attestation, releases are
never deleted and tags never moved, and a version that must not be picked is
listed in `YANKED` rather than removed. `cigo update` is written against
exactly this.

## The checklist

1. **Main is green** and holds everything the version ships: `cigo run ci`
   passes locally, and the last pull request's checks passed.
2. **The version.** `stick VERSION = "X.Y.Z"` in `orchestrate.cig`; the
   release job refuses a tag that disagrees with it. If the version needs a
   newer cig, raise `CIG_NEEDS` and the `# cig` header beside it, the floor
   in `bin/cigo` and `install.sh`, `CIG_VERSION` in `.github/workflows/ci.yml`,
   and the installs in the README and [cigo in CI](ci.md).
3. **The changelog.** The `Unreleased` section becomes `## X.Y.Z — date`,
   one entry per change a user sees, newest version first.
4. **The docs** say what the version does: the README's install block names
   the tag, [commands](commands.md) and [the manifest](manifest.md) have
   every new flag and key, `TOOLCHAINS.md` is regenerated when the knowledge
   base changed (`bin/cigo run toolchains-doc`).
5. **The licence gate** passes on the tree (`LICENSE`, `NOTICE`, `LICENSES/`,
   `REUSE.toml`; the code Apache-2.0, the docs CC BY 4.0, the examples
   CC0 1.0).
6. **One pull request** carries the bump; merge it with a merge commit.
7. **The tag**, annotated, on the merge commit:

   ```sh
   git switch main && git pull --ff-only
   git tag -a vX.Y.Z -m "cig-orchestrator X.Y.Z: <one line>"
   git push origin vX.Y.Z
   ```

   The `release` job in `ci.yml` runs on the tag after the checks pass: it
   builds `cig-orchestrator-vX.Y.Z.tar.gz` (the tool, the launcher, the
   installer, the licences, the README, the changelog, `TOOLCHAINS.md`,
   `YANKED`, the docs), writes the `.sha256`, attests the build
   (`actions/attest-build-provenance`), and publishes the release with
   `LICENSE` and `NOTICE` beside the assets.
8. **Check it as a user would**: `cigo update --check` sees the version,
   `cigo update` installs it, `gh attestation verify cig-orchestrator-vX.Y.Z.tar.gz
   -R otmof-ops/cig-orchestrator` passes.

## Yanking

A release that must not be installed by `cigo update` is listed in `YANKED`,
one version per line with the reason, and the fix is the next patch version.
The release and its tag stay: `cigo update --to=X.Y.Z` still installs a
yanked version for whoever needs that one on purpose.

## Pre-releases

A tag `vX.Y.Z-rc.1` marked as a pre-release on GitHub is picked only by a
cigo whose `update_channel` is `prerelease` (`cigo config update_channel
prerelease`).
