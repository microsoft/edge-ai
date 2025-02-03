# DevContainer

This DevContainer is intended to simplify local development and ensure all contributors are using the same local dependencies to build and run this solution.

## Git

A small amount of configuration may be required when setting up your DevContainer for the first time.

### Git config

Remote-Containers should copy your gitconfig settings from your local machine, but you may be asked to configure your global git settings when developing in the container.

```sh
git config --global user.name "Your Name"
git config --global user.email "your.email@address"
```

### Configuring SSH

For SSH to work with your local SSH keys in the DevContainer, you must configure an SSH agent using [these instructions](https://code.visualstudio.com/docs/remote/containers#_sharing-git-credentials-with-your-container).

Note: If you are running Windows as your host OS and launch VS Code from the start menu or PowerShell, use the Windows instructions (even if you're using WSL/WSL2 to run a Linux terminal for git)

## Linting

Run ALL linters

```sh
npm run lint
```

To fix basic linting issues, run the following:

```sh
npm run lint-fix
```

### Markdown linting

The linter run as part of PR validation is installed and configured in the DevContainer, making it possible to check your markdown before committing & PR.

```sh
npm run mdlint
```

To fix basic markdown linting issues, run the following:

```sh
npm run mdlint-fix
```

> **NOTE**
>
> Because not all rules include fix information when reporting errors, fixes may overlap, and not all errors are fixable, `fix` will not usually address all errors.

### Spell checking

Cspell checker runs as part of PR validation and is installed and configured in the DevContainer, which makes it possible to check your language basics before committing & PR.

```sh
npm run cspell
```

> **NOTE**
>
> If cspell detects an unknown word which should be ignored, add the word to the excluded word dictionary file `cspell-cse.txt`. If you think it's a common computing word, you can make a PR against [the cspell software terms dictionary](https://github.com/streetsidesoftware/cspell-dicts/tree/main/dictionaries/software-terms/src)

## Updates

If you need to change this DevContainer, please ensure that the changes maintain consistency with the production build pipeline.

## Codespaces

This DevContainer configuration enables you to use [GitHub Codespaces](https://github.com/features/codespaces) instead of editing the docs locally in VS Code.
