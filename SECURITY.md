# Security policy

## Supported versions

Security fixes target the latest release on `main` while the package is below
1.0.

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting for this repository. Do
not open a public issue containing credentials, private endpoints, exploit
details, or user data.

## Network boundary

The package does not persist tokens. Authentication should be supplied through
`headerProvider` and must not be logged. Applications remain responsible for
TLS policy, certificate configuration, secret storage, response redaction,
authorization, and domain-level validation.
