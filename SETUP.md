# Setup checklist

Secrets and repo variables that maven-ci-standards-generated workflows need but
that no automation is allowed to set on your behalf. Each feature group
maintains its own section below; re-running that group's `update` or
`reconfigure` command only replaces its own marked region.

<!-- maven-ci-standards:badges:setup-checklist:start -->
## badges

- `vars.GIST_ID`: set (`2561f0cb8277be7395802851def325bd`).
- `GIST_SECRET`: **missing**. Needed because the `vulnerabilities` badge reads
  a computed metric out of a private Gist. Set it yourself:
  ```
  gh secret set GIST_SECRET --repo Security4Media/pgp-keys-map
  ```
  Must be a classic PAT scoped to `gist` only (not fine-grained, not
  repo-scoped) — `schneegans/dynamic-badges-action` writes to the Gist API,
  which classic PATs cover more simply.
<!-- maven-ci-standards:badges:setup-checklist:end -->
