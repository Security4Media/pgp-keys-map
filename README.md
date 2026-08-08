# pgp-keys-map

<!-- maven-ci-standards:badges:start -->
[![build](https://github.com/Security4Media/pgp-keys-map/actions/workflows/build-test.yml/badge.svg?branch=main)](https://github.com/Security4Media/pgp-keys-map/actions/workflows/build-test.yml?query=branch%3Amain)
[![vulnerabilities](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/BadrTad/2561f0cb8277be7395802851def325bd/raw/vulnerabilities.json)](https://github.com/Security4Media/pgp-keys-map/actions/workflows/security-scan.yml?query=branch%3Amain)
[![release](https://img.shields.io/github/v/release/Security4Media/pgp-keys-map)](https://github.com/Security4Media/pgp-keys-map/releases/latest)
[![sbom](https://img.shields.io/badge/sbom-cyclonedx-blue)](https://github.com/Security4Media/pgp-keys-map/releases/latest)
[![license](https://img.shields.io/github/license/Security4Media/pgp-keys-map)](LICENSE)
[![license compliance](https://github.com/Security4Media/pgp-keys-map/actions/workflows/license-compliance.yml/badge.svg?branch=main)](https://github.com/Security4Media/pgp-keys-map/actions/workflows/license-compliance.yml?query=branch%3Amain)
[![docs](https://img.shields.io/badge/docs-javadoc-blue)](README.md#generating-documentation-locally)
<!-- maven-ci-standards:badges:end -->

<!-- maven-ci-standards:docs:start -->
## Generating documentation locally

This artifact packages a resource file (`pgp-keys-map.list`), not Java source, so there is no
real Javadoc to generate (`mvn javadoc:javadoc` produces nothing here). Releases still attach a
placeholder `-javadoc.jar` (see `src/main/javadoc/README.txt`) only because Maven Central's
upload validation requires one for jar-packaged artifacts.
<!-- maven-ci-standards:docs:end -->

Single source of truth for the `pgp-keys-map.list` used by
[pgpverify-maven-plugin](https://github.com/s4u/pgpverify-maven-plugin) across
Security4Media's Maven repositories.

Before this repo existed, each consuming project kept its own copy of the file
and they drifted apart. This repo packages the list as a small jar, published
to GitHub Packages, so every project can depend on the same version instead of
maintaining its own copy.

## Consuming this artifact

Declare it as a `pgpverify-maven-plugin` plugin dependency and reference it
with a bare classpath-relative path (leading slash, no scheme prefix - that's
the syntax the plugin itself uses for a keys map bundled inside a dependency
jar; `classpath:pgp-keys-map.list` looks more explicit but pgpverify-maven-plugin
1.19.1 doesn't recognize it and fails with "Could not find resource"):

```xml
<plugin>
    <groupId>org.simplify4u.plugins</groupId>
    <artifactId>pgpverify-maven-plugin</artifactId>
    <version>1.19.1</version>
    <executions>
        <execution>
            <goals>
                <goal>check</goal>
            </goals>
        </execution>
    </executions>
    <configuration>
        <keysMapLocations>
            <keysMapLocation>
                <location>/pgp-keys-map.list</location>
            </keysMapLocation>
            <!-- Project-specific additions, kept in the consuming repo, loaded
                 after the shared list. Can only ADD coverage for coordinates
                 the shared list doesn't have yet - see "Overriding an entry"
                 below for why it can't replace one that's already there. -->
            <keysMapLocation>
                <location>${maven.multiModuleProjectDirectory}/pgp-keys-map.local.list</location>
            </keysMapLocation>
        </keysMapLocations>
        <verifyPlugins>true</verifyPlugins>
        <verifyPluginDependencies>true</verifyPluginDependencies>
        <verifyAtypical>true</verifyAtypical>
        <!-- Catches an accidental byte-identical duplicate key entry for the
             same coordinate. It does NOT catch two DIFFERENT keys declared
             for the same coordinate across locations - see below. -->
        <failDuplicateKeyItem>true</failDuplicateKeyItem>
    </configuration>
    <dependencies>
        <dependency>
            <groupId>org.security4media</groupId>
            <artifactId>pgp-keys-map</artifactId>
            <version><!-- latest release --></version>
        </dependency>
    </dependencies>
</plugin>
```

### Overriding an entry from the shared list

You can't, from the consuming project. When the same coordinate pattern
appears in more than one `keysMapLocation`, `pgpverify-maven-plugin` always
unions the key items from every location - there's no configuration that
makes one location's entry replace another's for the same coordinate.
`excludes` on a `keysMapLocation` filters which of *that file's own* entries
get loaded (by the special `noSig`/`noKey`/`badSig`/`any` markers, not by
coordinate); it can't suppress a different location's entry for the same
coordinate. `failDuplicateKeyItem` only fires on a byte-identical duplicate
key string for the same coordinate, so it won't catch a local file that adds
a *different* key for a coordinate the shared list already covers - that
silently unions both keys as trusted instead of failing.

In practice this means a local `pgp-keys-map.local.list` can only add
coverage for coordinates the shared list doesn't have yet. If a shared
entry needs to change - wrong key, rotated key, compromised key - that has
to happen here, in this repo: open an issue or PR against
`src/main/resources/pgp-keys-map.list` rather than trying to shadow it
locally.

## Maintaining this list

Add new entries at the bottom, under a comment describing where they came
from. Every entry should be verified by actually running
`pgpverify-maven-plugin` against the consuming project's resolved dependency
tree - it cryptographically verifies each artifact's signature and prints the
exact `<coordinate> = <keyID>` line to add for anything not yet covered. Don't
hand-write key IDs.

### Versioning: pin a range, not an exact version

Once you've verified a version, pin it as a lower-bounded range instead of an
exact version:

```
groupId:artifactId:[1.2.3,) = 0xKEYID
```

This trusts the key you verified for that version and any later release
signed by the same key, so a routine patch bump doesn't need a list update.
Most of the upstream-inherited part of this file already works this way -
most entries have no version at all.

Don't drop the lower bound entirely (`groupId:artifactId = 0xKEYID`, matching
every version ever released) unless the key belongs to a long-established
organization with a stable release process (Apache, Eclipse Foundation,
OWASP, ...). For a smaller or single-maintainer project, keep the lower bound
at the version you actually checked, so you're not retroactively trusting a
release you never looked at.

`pgpverify-maven-plugin` has no `*` wildcard for the version field, only
ranges or omitting the version entirely (which then matches everything). A
literal `*` there isn't valid syntax.

### When to touch this file by hand

- **A new artifact or plugin appears in a dependency tree** - verify it for
  real (see above), then pin a lower-bounded range from that point forward.
- **A bounded range's upper limit is hit** (a new major version needs
  adding) - re-verify explicitly instead of widening the range blindly. A
  major bump is exactly where a maintainer handoff or infrastructure change
  is most likely.
- **Key rotation** - add the new key alongside the old one, never delete it,
  and comment why and when (see the `commons-io`/`commons-codec` entries for
  the pattern).
- **Upstream key revoked at the keyserver level** - if a project's key was
  revoked upstream and its public key may no longer be fetchable from (some)
  keyservers, but you still want to trust artifacts already signed with it,
  negate it with `!0xKEYID` instead of deleting the line (see the
  `com.stripe` and `net.sourceforge.pmd` entries). This is what `!0xKEYID`
  actually does - `allowNoPublicKey`, checked only when the public key can't
  be resolved. It is **not** a way to mark a key as no longer trusted: a
  negated entry never blocks a match against a separate, non-negated entry
  for the same fingerprint, and it does nothing if the public key is still
  normally fetchable (which is the case for any key Security4Media itself
  controls).
- **One of our own keys is compromised** - negation doesn't help here. Delete
  or replace the positive entry (`org.security4media.crypto:*`, etc.)
  outright; there's no safe alternative that keeps the old line in place.
- **Periodic review** - broad or unbounded entries are worth a second look
  whenever this file is already open for something else, especially for a
  key nobody's checked in years.
