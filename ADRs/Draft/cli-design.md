# CLI Design for AI on Edge - IaC fro Edge

Date: **2024-10-09** [Format=YYYY-MM-DD]

## Status

- [x] Draft
- [ ] Proposed
- [ ] Accepted
- [ ] Deprecated
- [ ] Superseded by 0002

## Decision

Select build vs buy of compiler/generator of IaC, scripts and charts for AI on Edge solutions.

## Context

A key component of the M1 release of the "IaC for Edge" project of the "AI on Edge" Flagship Accelerator is the implementation of a compiler or generator that can create IaC, scripts and workload charts, capable of replicating the as-built edge computing cluster environments under development at ***REMOVED***, ***REMOVED***, ***REMOVED***, and ***REMOVED***.

General function of the compiler/generator will be as follows:

- Using a "solution template", the compiler will load an empty, logical "solution model" representing the target output
- Snippet IaC for solution components, scripts, and charts are read from text files and loaded into the logical "solution model"
- The compiler stitches the snippets together based on deployment layers and dependency flows annotated in the solution template and hydrates the logical "solution model"
- The "solution model" is exported to an "output" directory as Bicep or Terraform for manual execution or automation/GitOps workflow execution

We need to decide on a build vs buy approach for the generator; choosing between developing an in-house tool vs using existing OSS solutions for project scaffolding/project templates.  

## Decision drivers

The primary drivers for built compiler/generator or use of an existing tool are:

- be lightweight and flexible in support of the project's current incubation period, and unknown terminal state
- handle a variety of language/file formats (Bicep, Terraform, powershell, bash, YAML for charts/seeds)
- use frameworks/technology well known to S500 customer teams operating edge environments

## Considered options

There are numerous ways to achieve this outcome, including using existing project scaffolding or project generator toolchains, such as:

- Yeoman
  - Pros: flexible in building/scaffolding multiple project types, active extension into the VSCode environment underway
  - Cons: Core project has not been maintained since 2016, not broadly known to customer engineers, steep learning curve for sub-generator development
- Ruby on Rails built-in "Scaffold" capability
  - Pros: flexible in building/scaffolding multiple project types
  - Cons: Base language not broadly known to customer engineers
- Cargo
  - Pros: flexible in building/scaffolding multiple project types, understood by early-adopter customers
  - Cons: Ecosystem not broadly known to customer engineers  
- Ritchie CLI
  - Pros: flexible in building/scaffolding multiple project types
  - Cons: Core project has not been maintained since 2016, not broadly known to customer engineers  
- Mustache or Jinja templates
  - Pros: mildly known to to customer engineers, provides flexibility and speed for initial implementation, could reuse core of Project Coral to accelerate
  - Cons: custom coded solution, not likely usable for cross-AF integration without significant work and governance
- No CLI and just raw IaC
  - Pros: less work to bootstrap and more natural/idiomatic flow for Terraform & Bicep outputs
  - Cons:
    - There is a large body of shared scripts and disk image templates that need to be managed for both output formats
    - Uniformity is a forcing function when the same tooling outputs multiple formats
    - Limited ability to create single "solution" files representing different solution types, or solution descriptors must be duplicated for each output format
    - More challenging to extend to additional output formats such as Powershell or Bash wrapping Az CLI commands for OEM/ODM or "boxed product" solutions in B2B scenarios 

## Decision Conclusion

The IaC for Edge project of the AI on Edge Flagship Accelerator has chosen to build the initial compiler/generator using Mustache/Jinja templates to expedite the incubation phase of the project.

## Consequences

Engineering team will likely need to adopt a more mature scaffolding framework in the future as project capability and complexity grows.
