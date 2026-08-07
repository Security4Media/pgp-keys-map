# CI/CD setup checklist

<!-- Generated/updated by the maven-ci-standards Claude Code plugin. Every setup command
     (/maven-ci-standards:<group>) that needs a secret, a repo variable, or a manual one-time
     action appends its own rows to the relevant section below rather than creating its own
     checklist file - re-run a group's setup/update command after resolving an item to keep this
     file in sync with what is actually configured. Leave a checked-off row checked even after
     re-runs; this file is a record of what was set up, not only a to-do list. -->

## Secrets

Run `gh secret list` in this repo to see what already exists; add anything missing with
`gh secret set <NAME>` (this file and any chat session never carries a secret's actual value,
only its name).

<!-- release group -->
- [x] `RELEASE_PLEASE_TOKEN`, a PAT or GitHub App installation token with `contents:write`,
  `pull-requests:write`, and `issues:write` on this repo. Required whenever release-please is
  enabled. Must NOT be the default `secrets.GITHUB_TOKEN`, GitHub's anti-recursion guard would
  silently stop the release it creates from triggering the publish workflows. (already set)
- [x] `GPG_SIGNING_KEY`, the exported private GPG key (ASCII-armored) used to sign released
  artifacts. Required once GitHub Packages or Maven Central publishing is enabled (the `release`
  Maven profile signs every artifact it deploys). (already set)
- [x] `GPG_SIGNING_KEY_PASSPHRASE`, the passphrase protecting the key above. (already set)
- [x] `CENTRAL_PORTAL_TOKEN`, a Central Portal **user token** pair generated at
  https://central.sonatype.com/account (Account -> Generate User Token), not a legacy Sonatype
  OSSRH/JIRA login (that flow was retired). Required for Maven Central publishing. (already set)
- [x] `CENTRAL_PORTAL_USERNAME`, the other half of the same user token pair above. (already set)

<!-- other groups append their own secrets rows here -->

## Repo variables

Run `gh variable list` in this repo to see what already exists. None currently required.

## Manual one-time steps

<!-- release group -->
- [x] Confirm `pom.xml` has a `<distributionManagement>` entry with `<id>github</id>` pointing at
  `https://maven.pkg.github.com/Security4Media/pgp-keys-map`, required for GitHub Packages
  publishing. (already present)
- [x] `<url>`, `<licenses>`, `<developers>`, and `<scm>` added/verified in `pom.xml` for Central
  Portal's upload validation. `<developers>` deliberately uses an org-level identity
  (`maintainers@security4media.org`) rather than an individual's name/email, so no one's
  personal address ends up permanently public on Central - confirm that mailbox actually
  exists and is monitored before the first real Central deploy.
- [x] **One-time Central Portal namespace verification for `org.security4media`.** Done. This
  gates every future Central deploy under this groupId, not just this repo's.
- [x] Publish the same GPG key's **public** key to a public keyserver. Done:
  `448C17164DA1EF787059C31C176E655BBA8686E3` (Security4Media Releases
  &lt;releases@security4media.org&gt;) sent to `keys.openpgp.org` and confirmed resolvable by
  fingerprint (`https://keys.openpgp.org/vks/v1/by-fingerprint/448C17164DA1EF787059C31C176E655BBA8686E3`
  returns HTTP 200). Note: keys.openpgp.org withholds the UID/email from public search until
  verified via the confirmation link it emails to that address - fingerprint lookup (what Central
  Portal and this repo's own `pgp-keys-map.list` both key off) already works regardless of that.
- [x] ~~Backfill the `v1.0.0` GitHub Release manually via `workflow_dispatch`~~ - tried, failed,
  abandoned on purpose. The `v1.0.0` tag predates `publish-maven-central.yml` and PR #5's pom.xml
  changes, so checking out that tag for the backfill gets a pom.xml with no `central`/source/
  javadoc/SBOM plugins at all; Maven silently fell through to the GitHub Packages target instead
  and 401'd on credentials meant for Central. Also, `pgp-keys-map.list` itself changed
  functionally since that tag (duplicate entries merged, invalid `:*`-for-version entries fixed),
  so republishing "1.0.0" from current content wouldn't be a faithful snapshot of what was
  actually tagged anyway. Decision: leave `v1.0.0` unpublished on Central; the next real release
  is the first one that reaches it. `publish-maven-central.yml` itself needs no code fix - every
  future tag is cut from post-PR#5 main, so its checkout-by-ref logic is fine going forward.
- [x] **release-please was stuck failing on every push to `main`** (separate bug): a leftover
  `"release-as": "1.0.0"` in `release-please-config.json` kept forcing every cycle back to a
  version that already exists as a tag, so release creation failed with
  `{"code":"already_exists","field":"tag_name"}` on every run since PR #5 merged. Fixed in PR #7
  (merged): override removed.
- [x] **Verified the next release-please run proposed a sane version bump.** It did - `1.1.0`
  (minor, from PR #5's `feat:` commit), via PR #8 (merged). The stray `autorelease: tagged` label
  left on PR #6 didn't cause any problem in practice.
- [x] **`v1.1.0` tagged, both publish workflows ran, artifact confirmed on Central.**
  `publish.yml` (GitHub Packages) succeeded outright. `publish-maven-central.yml`'s run itself
  shows as **cancelled**, not successful - but that's misleading: the actual upload/signing/bundle
  steps all completed and Central Portal confirmed the deployment would auto-publish; the run was
  only cancelled while it sat in the `waitUntil: published` polling step afterward (cancelled
  intentionally, not a failure). Confirmed directly:
  `curl -I https://repo.maven.apache.org/maven2/org/security4media/pgp-keys-map/1.1.0/pgp-keys-map-1.1.0.pom`
  → `200`. `v1.0.0` itself stays `404` per the decision above - `1.1.0` is the first version that
  actually reaches Central, which is what resolves
  [issue #4](https://github.com/Security4Media/pgp-keys-map/issues/4).
- [x] The cancelled run also skipped its "Attach SBOM to release" step (it ran after the step
  that got cancelled). Attached by hand: `gh release upload v1.1.0 target/bom.json`, built from
  the same `1.1.0` source. Nothing to do here going forward - a run that completes normally
  attaches it automatically.

<!-- docs group -->
- No secrets or variables are needed for the `docs` group.

<!-- other groups append their own rows here -->

## Future: making this repo public

Not started. Written up here as a checklist for whenever it's actually triggered - do not
execute any of this without a fresh, explicit go-ahead.

- [ ] **Resolve everything in flight first.** Merge or close every open PR, and check for other
  active branches/sessions on this repo before deleting anything. Never delete a branch you
  didn't create without confirming with whoever owns it.
- [ ] **Decide on the commit history separately from "going public."** Squashing `main` to one
  commit doesn't just remove old messages - `release-please` reads conventional-commit history
  to generate changelogs, so squashing breaks that going forward, not just retroactively.
  The actual content leaks (sibling-repo names in prose) are already fixed directly in the
  files, not in the commit history. If specific strings still need scrubbing from history,
  use a targeted `git filter-repo` pass on just those strings, not a full squash.
- [ ] **Delete only confirmed-stale branches**, after the step above.
- [ ] **Flip visibility**: `gh repo edit --visibility public`.
- [ ] **Add real branch protection** requiring the `CODEOWNERS` review on
  `pgp-keys-map.list` - this becomes available once the repo is public (or the org upgrades
  off the current plan), and is a hard gate rather than the review-visibility-only signal
  `CODEOWNERS` provides today.
