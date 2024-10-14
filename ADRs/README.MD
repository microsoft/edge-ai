# ADR Process

This document outlines the process and workflow for all Architecture Decision Record (ADR) regardless of the author of origin.

## When to draft ADRs

ADRs should be drafted for the following reasons:

- Proposal of a new feature or capability for the tool
- Updates to automation of this tool, including notification setting, workflows and build process
- Deprecation of an existing feature of the tool
- Changes to the project stucture

ADRs do not need to be drafted fo issue or bugs, unless addressing the issue or bug meets the above criteria.

## States

ADRs move through the following five (5) states:

- Draft
- Proposed
- Accepted
- Deprecated
- Superseded (by - link to outdated ADR)

Each state and migration between states is governed by a well defined progression:

### Draft

ADRs can enter a draft state regardless of their author of origin. Project leads may commit draft ADRs directly to main, whereas community members must submit their drafts via a pull request. ADR PRs from community members will be immediately merged to the main branch to record the idea, concept, feature, or change. Community members should update their clones, requesting a PR to submit their draft to main as soon as is reasonable, even as they continue work on the draft. Project leads may commit draft ADRs directly to main. Draft ADRs will be automatically deleted after 15 days of inactivity. ALL ADRs must enter via a draft state and progress through the subsequent process states, regardless of origin.

### Proposed

The Proposed state represents ADRs that have been reviewed by project leads for completion. Project leads have first right to request additional clarification or the coverage of missing perspective that may improve the detail and accuracy of the ADR. Project leads may not reject proposed ADRs at this stage simply because the proposal does not align with the current roadmap of the project. The Proposed state is simply to ensure that the ADR is complete enough for review by the broad project community.

PRs raised to migrate a draft ADR to proposed will adhere to the following rules:

- Unless there are open discussion comments on the draft PR, the draft ADR will progress to the Proposed state after 3 business days from the day of submission.
- Draft PRs can progress to the Proposed state after the PR has been approval by one (1) member of the project's lead team.
- PRs for submission to the Proposed state will be automatically closed after 15 days of inactivity by the author.  
- ADRs in the Proposed state have an open, five (5) day comment period for community members to contribute to or challenge any aspect of the ADR. After the 5 day period elapses, ADRs PRs will transition to a 3 day evaluation period by project leads who will ensure fitness of the ADR to the projects roadmap. Project leads have 3 days to address or close all open community comments on the PR, guided by the Product Owner. If all comments have been addressed and the PO approves the PR, the ADR will transition to the Accepted state. In the PO's absence, the project's Technical Lead can assume the PO's responsibilities and approve the PR for progression to the accepted state.

### Accepted

The Accepted state represents ADRs that have been reviewed for completeness and approved by the project leads and have progressed through a period of RFC from the broader project community. (To Be Completed)

### Deprecated

### Superseded

## FAQ
