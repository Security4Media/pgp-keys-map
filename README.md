# pgp-keys-map

Single source of truth for the `pgp-keys-map.list` used by
[pgpverify-maven-plugin](https://github.com/s4u/pgpverify-maven-plugin) across
Security4Media's Maven repositories (`jce-providers`, `cmp-client-component`,
`c2pa-cmp-client`, `cmp-app`, ...).

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

## Updating the list

Add new entries at the bottom, under a comment describing where they came
from. Every entry should be verified by actually running
`pgpverify-maven-plugin` against the consuming project's resolved dependency
tree - it cryptographically verifies each artifact's signature and prints the
exact `<coordinate> = <keyID>` line to add for anything not yet covered. Don't
hand-write key IDs.
