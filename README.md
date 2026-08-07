# pgp-keys-map

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

Declare it as a `pgpverify-maven-plugin` plugin dependency and reference it via
a `classpath:` location, exactly like the upstream community list
(`org.simplify4u:pgp-keys-map`) is already consumed:

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
                <location>classpath:pgp-keys-map.list</location>
            </keysMapLocation>
            <!-- Project-specific additions/overrides, kept in the consuming
                 repo, loaded after the shared list. -->
            <keysMapLocation>
                <location>${maven.multiModuleProjectDirectory}/pgp-keys-map.local.list</location>
            </keysMapLocation>
        </keysMapLocations>
        <verifyPlugins>true</verifyPluginDependencies>
        <verifyAtypical>true</verifyAtypical>
        <!-- Fail loudly instead of silently merging if a coordinate appears in
             both the shared list and the local override. -->
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

`pgpverify-maven-plugin` merges/updates key items rather than cleanly
replacing them when the same coordinate pattern appears in more than one
`keysMapLocation`. To genuinely override a shared entry (e.g. a rotated key),
exclude that coordinate from the shared location instead of just adding a
conflicting line to the local file:

```xml
<keysMapLocation>
    <location>classpath:pgp-keys-map.list</location>
    <excludes>
        <exclude>org.example:some-artifact</exclude>
    </excludes>
</keysMapLocation>
```

`failDuplicateKeyItem` (enabled above) turns any accidental, un-excluded
overlap into a build failure instead of a silent merge.

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
- **Revocation or compromise** - negate the key with `!0xKEYID` instead of
  silently deleting the line (see the `com.stripe`, `net.sourceforge.pmd`,
  and `io.vavr` entries for examples).
- **Periodic review** - broad or unbounded entries are worth a second look
  whenever this file is already open for something else, especially for a
  key nobody's checked in years.
