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

## Considered options (optional)

What were the options that were considered?

- 70% pf all language use for IoT Edge and Hub was with Javascript, with .NET as in the majority use for cloud side service controllers  
- Python will play as a driver in edge solutions focused on AI, but will likely be relegated to API and data science workloads
- Most "popular" languages are moving towards support of WASM/WASI decreasing pressure on customers needing rust ecosystem expertise
- Python has very intuitive string handling/parsing and templating engines have a low learning curve
- Javas/Typescript can be challenging for complex string/file parsing, runtime is pervasive and easy to work with in automation contexts
- It's often difficult in edge customer environments to secure less common runtimes, even for developer machines

## Decision Conclusion

The CLI will be written in JavaScript/Typescript and use the Node runtime.

## Consequences

- Consumers will have to check for CVEs and package updates frequently.
- Project should security scan all dependant packages.
- Project should report build status on main readme.
- Automated dependency issue tracker must be wired to repository.
