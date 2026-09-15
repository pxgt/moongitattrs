# Security Policy

MoonGitAttrs only parses caller-provided text and does not execute attribute
drivers or modify a repository. Even so, malformed input may expose denial of
service or incorrect policy decisions in applications that embed the library.

Please report security-sensitive problems privately through GitHub's security
advisory feature for `pxgt/moongitattrs`. Do not include secrets or private
repository content in a public issue. The current `0.1.x` line receives security
fixes while it is actively maintained.
