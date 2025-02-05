# Contributing to the AI on Edge Flagship Accelerator

First off, thanks for taking the time to contribute! ❤️

All types of contributions are encouraged and valued. See the [Table of Contents](#table-of-contents) for different ways to help and details about how this project handles them. Please make sure to read the relevant section before making your contribution. It will make it a lot easier for us maintainers and smooth out the experience for all involved. The community looks forward to your contributions. 🎉

> And if you like the project, but just don't have time to contribute, that's fine. There are other easy ways to support the project and show your appreciation, which we would also be very happy about:
>
> - Star the project or add it to your favorites
> - Mention the project to your peer studio crews and tell your work friends/colleagues

## Table of Contents

- [Contributing to the AI on Edge Flagship Accelerator](#contributing-to-the-ai-on-edge-flagship-accelerator)
  - [Table of Contents](#table-of-contents)
  - [Code of Conduct](#code-of-conduct)
  - [I Have a Question](#i-have-a-question)
  - [I Want To Contribute](#i-want-to-contribute)
    - [Reporting Bugs](#reporting-bugs)
      - [Before Submitting a Bug Report](#before-submitting-a-bug-report)
      - [How Do I Submit a Good Bug Report?](#how-do-i-submit-a-good-bug-report)
    - [Suggesting Enhancements](#suggesting-enhancements)
      - [Before Submitting an Enhancement](#before-submitting-an-enhancement)
      - [How Do I Submit a Good Enhancement Suggestion?](#how-do-i-submit-a-good-enhancement-suggestion)
    - [Your First Code Contribution](#your-first-code-contribution)
    - [Improving The Documentation](#improving-the-documentation)
  - [Style Guides](#style-guides)
    - [Linting](#linting)
      - [Markdown linting](#markdown-linting)
      - [Spell checking](#spell-checking)
    - [Linting Updates](#linting-updates)
    - [Commit Messages](#commit-messages)
  - [Attribution](#attribution)

## Code of Conduct

This project and everyone participating in it is governed by the
[Code of Conduct](./CODE_OF_CONDUCT.md).
By participating, you are expected to uphold this code. Please see the [Code of Conduct](./CODE_OF_CONDUCT.md) instructions on how to report unacceptable behavior.

## I Have a Question

> If you want to ask a question, we assume that you have read the available [Documentation](./docs/README.md).

Before you ask a question, it is best to search for existing [Issues](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_queries/query/a8d3e164-fe33-43a9-83c3-b60c4c51934d/) that might help you. In case you have found a suitable issue and still need clarification, you can write your question in this issue. It is also advisable to search the internet for answers first.

If you then still feel the need to ask a question and need clarification, we recommend the following:

- Open an [Issue](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_workitems/create/Issue).
- Provide as much context as you can about what you're running into.
- Provide project and platform versions (nodejs, npm, etc), depending on what seems relevant.

We will then take care of the issue as soon as possible.

## I Want To Contribute

> ### Legal Notice
>
> When contributing to this project, you must agree that you have authored 100% of the content, that you have the necessary rights to the content and that the content you contribute may be provided under the project license.

### Reporting Bugs

#### Before Submitting a Bug Report

A good bug report shouldn't leave others needing to chase you up for more information. Therefore, we ask you to investigate carefully, collect information and describe the issue in detail in your report. Please complete the following steps in advance to help us fix any potential bug as fast as possible.

- Make sure that you are using the latest version of the project.
- Determine if your bug is really a bug and not an error on your side e.g. using incompatible environment components/versions (Make sure that you have read the [documentation](/docs/README.md). If you are looking for support, you might want to check [this section](#i-have-a-question)).
- To see if other users have experienced (and potentially already solved) the same issue you are having, check if there is not already a bug report existing for your bug or error in the [bug tracker](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_queries/query/a8d3e164-fe33-43a9-83c3-b60c4c51934d/).
- Also make sure to search the internet (including internal and external Stack Overflow) to see if users outside of the GitHub community have discussed the issue.
- Collect information about the bug:
  - Stack trace (Traceback)
  - OS, Platform and Version (Windows, Linux, macOS, x86, ARM)
  - Version of the interpreter, compiler, SDK, runtime environment, package manager, depending on what seems relevant.
  - Possibly your input and the output
- Can you reliably reproduce the issue? And can you also reproduce it with older versions?

#### How Do I Submit a Good Bug Report?

> You must never report security related issues, vulnerabilities or bugs including sensitive information to the issue tracker, or elsewhere in public. Instead sensitive bugs must be filed using [Report It Now](https://aka.ms/reportitnow).

We use Azure DevOps issues to track bugs and errors. If you run into an issue with the project:

- Open an [Issue](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_workitems/create/Issue). (Since we can't be sure at this point whether it is a bug or not, we ask you not to talk about a "bug" yet and not to label the issue as a "bug.")
- Explain the behavior you would expect and the actual behavior.
- Please provide as much context as possible and describe the *reproduction steps* that someone else can follow to recreate the issue on their own. This usually includes your code. For good bug reports you should isolate the problem and create a reduced test case.
- Provide the information you collected in the previous section.

Once it's filed:

- The project team will label the issue accordingly.
- A team member will try to reproduce the issue with your provided steps. If there are no reproduction steps or no obvious way to reproduce the issue, the team will ask you for those steps and mark the issue as `needs-repro`. Bugs with the `needs-repro` tag will not be addressed until they are reproduced.
- If the team is able to reproduce the issue, it will be marked `needs-fix`, as well as possibly other tags (such as `critical`), and the issue will be left to be [implemented by someone](#your-first-code-contribution).

### Suggesting Enhancements

This section guides you through submitting an enhancement suggestion for CONTRIBUTING.md, **including completely new features and minor improvements to existing functionality**. Following these guidelines will help maintainers and the community to understand your suggestion and find related suggestions.

#### Before Submitting an Enhancement

- Make sure that you are using the latest version.
- Read the [documentation](./docs/README.md) carefully and find out if the functionality is already covered, maybe by an individual configuration.
- Perform a [search](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_workitems/) to see if the enhancement has already been suggested. If it has, add a comment to the existing workitem instead of opening a new one.
- Find out whether your idea fits with the scope and aims of the project. It's up to you to make a strong case to convince the project's developers of the merits of this feature. Keep in mind that we want features that will be useful to the majority of our users and not just a small subset. If you're just targeting a minority of users, consider writing an add-on/plugin library or a sub-project.

#### How Do I Submit a Good Enhancement Suggestion?

Enhancement suggestions are tracked as [Azure DevOps Features](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_backlogs/backlog/IaC%20for%20the%20Edge%20Team/Features).

- Use a **clear and descriptive title** for the issue to identify the suggestion.
- Provide a **step-by-step description of the suggested enhancement** in as many details as possible.
- **Describe the current behavior** and **explain which behavior you expected to see instead** and why. At this point you can also tell which alternatives do not work for you.
- You may want to **include screenshots and animated GIFs** which help you demonstrate the steps or point out the part which the suggestion is related to. You can use [this tool](https://www.cockos.com/licecap/) to record GIFs on macOS and Windows, and [this tool](https://github.com/colinkeenan/silentcast) or [this tool](https://github.com/GNOME/byzanz) on Linux.
- **Explain why this enhancement would be useful** to most CONTRIBUTING.md users. You may also want to point out the other projects that solved it better and which could serve as inspiration.

### Your First Code Contribution

When contributing code to the project, please consider the following guidance:

- Assign a workitem to yourself before beginning any effort, and set the item's status field accordingly.
- If a work item for your contribution does not exist, [please file an issue](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_workitems/create/Issue) first to engage the project's PO, TPM, or Tech Lead for guidance.
- Commits (or at least one in a commit chain) should reference a User Story or Task item from the backlog for traceability.
- When creating a PR, ensure descriptions use [Azure DevOps notation to close associated work items](https://learn.microsoft.com/en-us/azure/devops/repos/git/resolution-mentions?view=azure-devops).
- All code PRs destined for the `main` branch must be reviewed by two reviewers including one of the following:
  - Tech Lead: Bill Berry
  - Architect: Tim Park, Paul Bouwer
  - Maintainers: Vy Ta, Katrien De Graeve, or Allen Greaves
- All ADRs and Security Plans must be reviewed by two reviewers including the following personnel:
  - Product Owner: Larry Lieberman
  - AI/ML related ADRs: Cheng Chen, Ren Silva
  - Security related ADRs & Plans: Andrew Malkov

This project also includes a Dev Container for development work, and using that dev container is preferred, to ensure you are using the same toolchains and tool versions as other contributors. You can read more about the Dev Container in its [ReadMe](./.devcontainer/README.md).

### Improving The Documentation

If you see issues with the documentation, please follow the [your first code contribution](#your-first-code-contribution) guidance.

## Style Guides

This project uses MegaLinter with numerous custom configured linters. These linters can be run locally to ensure that code reads the same across the project. Please review the following guidance:

### Linting

Run ALL linters

```sh
npm run lint
```

To fix basic linting issues, run the following:

```sh
npm run lint-fix
```

#### Markdown linting

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

#### Spell checking

Cspell checker runs as part of PR validation and is installed and configured in the DevContainer, which makes it possible to check your language basics before committing & PR.

```sh
npm run cspell
```

### Linting Updates

If you need to change the DevContainer, please ensure that the changes maintain consistency with the production build pipeline.

> **NOTE**
>
> If cspell detects an unknown word which should be ignored, add the word to the excluded word dictionary file `cspell-cse.txt`. If you think it's a common computing word, you can make a PR against [the cspell software terms dictionary](https://github.com/streetsidesoftware/cspell-dicts/tree/main/dictionaries/software-terms/src)

### Commit Messages

Ideally, at least one commit message in a PR includes a reference to the workitem that it addresses. We would appreciate if commits we descriptive and concise, however we also recognize there are times where `reverting the last change` is appropriate. Please use your judgement, squash commit when appropriate, and do your best to keep the commit history clean and readable.

## Attribution

This guide is based on the **contributing.md**. [Make your own](https://contributing.md/)!
