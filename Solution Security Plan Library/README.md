# Solution Security Plan Library

The Solution Security Plan Library is a collection of pre-constructed security plans that have been extracted and generalized from ISE's own customer projects. These security plans expose the decision making factors, constraints, threat analysis and context for a breadth of security/identity concerns that must be considered when building edge computing solutions.
The maintainers of this repository encourage wholesale reuse of this content, extension of existing security plans with common customer requirements/concerns, and contribution back to the library.

## Contributing

This project encourages the contribution of high-quality Security Plans that have been used in ISE engagements. Contributions require some normalization to a template format and removal of customer specific or NDA information. When contributing a Security Plan to the project, please consider the following guidance:

* Review the existing Security Plans in the library to see if an existing one can be extended or improved before contributing a new document.
* All Security Plans must be formatted as Markdown documents and use the `.md` file extension
* All Security Plans must follow the formatting of the [Security Plan template](./Security%20Plan%20Template.md)
* All Security Plans must use short, concise, English file names
* Security Plans may include optional language translations, please copy the Security Plan and add an intermediate, language extension using appropriate ISO 639 language codes (e.g. `CNCF Cluster Security Plan.en.md` and `CNCF Cluster Security Plan.zh.md` for English and Chinese)
* Assign a workitem to yourself before beginning any effort, and set the item's status field accordingly.
* If a work item for your contribution does not exist, [please file an issue](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_workitems/create/Issue) first to engage the project's PO, TPM, or Tech Lead for guidance.
* Commits (or at least one in a commit chain) should reference a User Story or Task item from the backlog for traceability.
* All Security Plans must be reviewed by two reviewers including the following personnel:
  * Product Owner (Larry Lieberman) or TPM (Mack Renard)
  * Security Specialist (Andrew Malkov)
