# Approaches to solution distribution

Date: **2021-10-10** [Format=YYYY-MM-DD]

## Status

- [x] Draft
- [ ] Proposed
- [ ] Accepted
- [ ] Deprecated
- [ ] Superseded by 0002

## Decision

Determine the initial distribution approach for the solution.

## Context

How this project (CLI tool, solution template file(s), and IaC/scripts/image definitions) is distributed is critical to both the complexity of maintenance and publishing, and to the opportunities for reuse in the context of MSFT customers consuming it. This tool currently has optimal opportunity for use in the context of manufacturing (discrete and process, including CPGs) edge computing engagements; product groups will not be targeting the development of industry solutions outside of manufacturing for atleast the next 9-12 months.

## Decision drivers (optional)

The primary drivers for distribution/reuse of this tool are:

- Developers at manufacturing customers are often prohibited from accessing public package repositories directly, meaning consumption via package distribution requires allow-listing with sufficient lead time for DevOps teams to pre-scan and copy packages internally.
- Customers do not NEED to use this tool as it could be utilized only by ISE crews and contents distributed to customers after an IaC generation run.
- Publishing packages as MSFT artifacts requires code signing, burdensome compliance requirements, additional reoccurring operational complexity (certificate expiry), only those with secure access workstations can work on automation infrastructure, and it will then necessitate an ongoing commitment from SolOps to keep publishing processes functioning.

## Considered options (optional)

The outcome here is one of a few choices:

- Publish public packages and take on the operational complexity of maintaining the process
- Publish internal packages which has less overhead as the code does not have to be signed, but the internal package repository will need ongoing operational support
- Consumption (public or internal) directly from the repository requires downloading the tool, potentially installing the tool's runtime (or the development of a Codespace), and then running the tool, which can be more error prone than running a downloaded package.

## Decision Conclusion

The tool will be provided only as a code package that requires downloading/cloning and running the tool in its host runtime to execute.

## Consequences

There is additional friction for consumption; however, requiring a clone may encourage contribution back to the project as developers will have the tool cloned locally. This decision also do not preclude distribution by package at a later date, when reuse is sufficiently high enough to justify the operational commitment.  
