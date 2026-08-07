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
- [ ] `CENTRAL_PORTAL_TOKEN`, a Central Portal **user token** pair generated at
  https://central.sonatype.com/account (Account -> Generate User Token), not a legacy Sonatype
  OSSRH/JIRA login (that flow was retired). Required for Maven Central publishing.
- [ ] `CENTRAL_PORTAL_USERNAME`, the other half of the same user token pair above.

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
  (`maintainers@security4media.org`) rather than an individual's name/email, per data-minimization
  preference - confirm that mailbox actually exists and is monitored before the first real
  Central deploy.
- [ ] **One-time Central Portal namespace verification for `org.security4media`.** Create/sign in
  to a Sonatype Central Portal account at https://central.sonatype.com, then verify ownership of
  the `org.security4media` namespace (typically via a DNS TXT record on a domain you control, or
  by proving ownership of the `Security4Media` GitHub org if using the `io.github.*`-style
  verification - check Central Portal's current namespace docs for the GitHub-org path). This
  gates every future Central deploy under this groupId, not just this repo's.
- [ ] Publish the same GPG key's **public** key to a public keyserver, e.g.
  `gpg --keyserver keys.openpgp.org --send-keys <KEY_ID>` (keys.openpgp.org is a reasonable
  default; Central Portal's own validation also accepts keyserver.ubuntu.com and pgp.mit.edu).
  Required for Maven Central; was not required for the existing GitHub Packages publishing, so
  may not have been done yet even though `GPG_SIGNING_KEY` is already set.
- [ ] The `v1.0.0` GitHub Release already exists and predates `publish-maven-central.yml`, so its
  `release: created` event already fired and won't re-trigger the new workflow. Once the two
  secrets above are set, backfill it manually: Actions -> "Publish package to Maven Central" ->
  "Run workflow" -> tag `v1.0.0`. Future releases publish automatically.

<!-- docs group -->
- No secrets or variables are needed for the `docs` group.

<!-- other groups append their own rows here -->
