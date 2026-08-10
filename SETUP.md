# Setup

<!-- maven-ci-standards:security:start -->
## Security (dependency safety/integrity/freshness)

Run these yourself, this plugin never captures secret values:

```bash
gh secret set OSS_INDEX_USERNAME  # recommended: raises Sonatype OSS Index's anonymous rate limit
gh secret set OSS_INDEX_PASSWORD  # recommended: paired with OSS_INDEX_USERNAME above
```

Also needed for the `vulnerabilities` README badge added in this update (owned by the `badges`
group, but the push step lives in this group's `security-scan.yml`):

```bash
gh secret set GIST_SECRET --repo Security4Media/pgp-keys-map
```

Must be a classic PAT scoped to `gist` only. `vars.GIST_ID` is already set.
<!-- maven-ci-standards:security:end -->
