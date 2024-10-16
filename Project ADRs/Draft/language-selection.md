# CLI development Language Selection

Date: **2021-10-24** [Format=YYYY-MM-DD]

## Status

- [ ] Draft
- [X] Proposed
- [ ] Accepted
- [ ] Deprecated
- [ ] Superseded by 0002

## Decision

Select language and runtime of compiler/generator of IaC, scripts and charts for AI on Edge solutions.

## Context

Selecting a language for the CLI is important for both consumption and contribution. On the consumption side there is friction in downloading a developer environment that is not easy to secure in constrained corporate environments. On the contribution front, selecting an ecosystem known by a majority of developers, and has a low learning curve for new developers is critical. Secondarily, the ability to easily process text files in a meta-programming/text parsing fashion is also within focus as a driving factor.  

## Decision drivers (optional)

The Primary drivers for this decision are related to ease of customer use and breath of community engagement/participation in maintaining and extending the tool.

- Community participation and ease of on-boarding developers for new contributions or through extension development efforts.
- Easy to run the tool in highly restrcted development and operational environments.
- 70% pf all language use for IoT Edge and Hub was with Javascript, with .NET as in the majority use for cloud side service controllers  
- Python will play as a driver in edge solutions focused on AI, but will likely be relegated to API and data science workloads
- Most "popular" languages are moving towards support of WASM/WASI decreasing pressure on customers needing rust ecosystem expertise
- Python has very intuitive string handling/parsing and template engines have a low learning curve
- Javas/Typescript can be challenging for complex string/file parsing, runtime is pervasive and easy to work with in automation contexts
- It's often difficult in edge customer environments to secure less common runtimes, even for developer machines

## Considered options (optional)

- JavaScript/TypeScript CLI with a Node runtime
- Vanilla Python
- Typed Python

Additional dependant package solutions, adding to the matrix of the above solutions include:

- JavaScript/TypeScript:
  - Mustache Templates (Familiar to devs for general string manipulation and formatting)
  - Existing project scaffolding tools, typically used for web application development

- Python/Typed Python
  - Jinja (ISE developers will have experience from the Playbook)
  - Mustache (Familiar to devs for general string manipulation and formatting)
  - Black (mostly transparent to devs/contributors, slower linting and formatting)
  - Ruff (mostly transparent to devs/contributors, fast linting and formatting)
  - Pip (mostly transparent to devs/contributors, common dependency and package resolver, slow'ish)
  - UV (mostly transparent to devs/contributors, high speed dependency and package resolver)

## Decision Conclusion

<<<<<<<< HEAD:Project ADRs/Proposed/language-selection.md
The CLI will be written in JavaScript/Typescript and use the Node runtime.
========
The CLI will be written in Typed Python and use the Jinja template engine, uv package resolver, Ruff for linting and formatting.
>>>>>>>> main:Project ADRs/Draft/language-selection.md

## Consequences

- Project consumers will have to check for CVEs and package updates frequently.
- Project should security scan all dependant packages.
- Project should report build status on main readme.
- Automated dependency issue tracker must be wired to repository.
