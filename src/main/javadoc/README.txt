This artifact packages a resource file (pgp-keys-map.list), not Java source, so there is no
real Javadoc to generate. This directory exists only so the release build can produce a
placeholder -javadoc.jar, which Maven Central's upload validation requires for jar-packaged
artifacts regardless of whether there is real Javadoc content.
