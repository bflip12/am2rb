# Security policy

## Supported versions

Security fixes go into the latest release and `main`.

## Reporting a vulnerability

Please **don't open a public issue** for security problems. Instead, report them privately through GitHub: on the repository's **Security** tab, choose **Report a vulnerability**.

Include what you found, how to reproduce it, and what an attacker could do with it. You'll get a reply within a week, and a fix or a plan within 30 days of the report being confirmed.

## Scope

am2rb runs locally and makes no network requests. The areas most worth a look are:

- Parsing untrusted input: Apple Music text exports, and tags in audio files.
- Anything that could make am2rb write outside the export folder or its own cache, or modify files in the DJ folder. The app must never do either.
