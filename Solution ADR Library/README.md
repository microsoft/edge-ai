# Solution ADR Library

The Solution ADR library are real, though anonymized, architectural decision records from ISE's own customer projects. These ADRs expose the decision making factors, constraints, and context for a breadth of decisions that must be made when building edge computing solutions. The maintainers of this repository encourage wholesale reuse of this content, extension of existing ADRs with common customer requirements, and contribution back to the library.

## Contributing

This project encourages the contribution of high-quality ADRs that have been used in ISE engagements. Contributions require some normalization to a template format and removal of customer specific or NDA information. When contributing and ADR to the project, please consider the following guidance:

* Review the existing ADRs in the library to see if an existing one can be extended or improved before contributing a new document.
* All ADRs must be formatted as Markdown documents and use the `.md` file extension
* All ADRs must follow the formatting of the [ADR template](./adr-template-solutions.md)
* All ADRs must use short, concise, English file names
* ADRs may include optional language translations, please copy the ADR and add an intermediate, language extension using appropriate ISO 639 language codes (e.g. `CNCF Cluster Selection.en.md` and `CNCF Cluster Selection.zh.md` for English and Chinese)
* Assign a workitem to yourself before beginning any effort, and set the item's status field accordingly.
* If a work item for your contribution does not exist, [please file an issue](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_workitems/create/Issue) first to engage the project's PO, TPM, or Tech Lead for guidance.
* Commits (or at least one in a commit chain) should reference a User Story or Task item from the backlog for traceability.
* All ADRs must be reviewed by two reviewers including the following personnel:
  * Product Owner (Larry Lieberman) or TPM (Mack Renard)
  * AI/ML related ADRs (Cheng Chen, Ren Silva)
  * Security related ADRs (Andrew Malkov)
