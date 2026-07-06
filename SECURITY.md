# Security Policy

This policy applies to every repository in the `traverse-framework` organization.

## Reporting a Vulnerability

**Do not open a public issue for a security vulnerability.**

Report it privately using GitHub's private vulnerability reporting: on the affected repository, go to **Security → Report a vulnerability** (or use the link `https://github.com/traverse-framework/<repo>/security/advisories/new`).

If private reporting is unavailable for some reason, email **enrico.piovesan10@gmail.com** with subject line `[SECURITY] <repo>: <short description>`.

Please include:

- the affected repository and version/commit
- a description of the vulnerability and its impact
- reproduction steps or a proof of concept if you have one

## What to Expect

- **Acknowledgement** within 7 days.
- **Assessment and fix plan** communicated within 30 days for confirmed issues.
- **Coordinated disclosure**: we ask that you keep the report private until a fix is released. We aim to release fixes within 90 days of a confirmed report, and we will credit reporters in the advisory unless they prefer otherwise.

## Supported Versions

Unless a repository states otherwise, only the **latest release** of each project receives security fixes.

## Scope Notes

- Vulnerabilities in dependencies should be reported upstream, but reports about how a Traverse repo *uses* a vulnerable dependency are welcome here.
- The `website` repository is a static site; reports about its content hosting infrastructure (GitHub Pages) belong to GitHub.
