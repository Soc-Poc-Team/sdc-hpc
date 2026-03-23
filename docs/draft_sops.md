# Draft: How to integrate sops-nix

Currently, all secrets are managed via a `config.toml` file at the repository root. That file is checked into our Git repository and mirrored to git-ce.

## Issues

- Credentials could be spilled into the public domain.
- Credentials are also spilled into the Nix store during builds.
- Switching branches or cherry-picking can cause problems with the secrets configuration.

## Current state

- `config.toml` can be assumed unchanged via `git update-index --assume-unchanged config.toml`.

## Interim actions taken

- All pushes that contain a file named `config.toml` are rejected by our internal Git instance — this is a temporary safeguard to avoid leaking credentials by accident.

## Vision

As we use direnv and Nix devshells, it should be possible to insert an abstraction layer between the current file-based configuration and its uses in the Nix options. SOPS allows us to safely check in secrets for every user. Using direnv we could perform logic like this:

1. Identify which encrypted secret file the current user can decrypt.
2. Select one (usually there should only be one that matches).
3. Process the secrets and feed them to Nix (this may require an impure approach — currently we are de facto always dirty on build).
4. Access secrets via an abstract layer within Nix so behavior does not change depending on whether a developer provides secrets via `config.toml` or via SOPS-encrypted files.

SOPS would then be used for development while a simple, approachable solution remains in place for production users.
