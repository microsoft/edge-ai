# Approaches to solution distribution

Date: **2021-10-10** [Format=YYYY-MM-DD]

## Status
[Use the appropriate status to represent this decision record]
- [x] Draft
- [ ] Proposed
- [ ] Accepted 
- [ ] Deprecated 
- [ ] Superseded by 0002

## Decision

Determine the initial distribution approach for the solution.

## Context

How this solution is distributed is critical to both the complexity of maintenance and publishing, and to the opportunities for reuse in the context of MSFT customers consuming it. This tool currently has optimal opportunity for use in the context of manufacturing (discrete and process, including CPGs) edge computing engagements; product groups will not be targeting the development of industry solutions outside of manufacturing for atleast the next 9-12 months. 

## Decision drivers (optional)

The primary drivers for distribution/reuse of this tool are:

* Developers at manufacturing customers are often prohibited from accessing public package repositories directly, meaning consumption via package distribution requires allow-listing with sufficient lead time.
* Customers do not NEED to use this tool as it could be utilized only by ISE crews and contents distributed to customers after generation. 
* Publishing packages as MSFT artifacts requires code signing, burdensome compliance requirements, additional reoccurring operational complexity (certificate expiry), and only those with secure access workstations can work on automation infrastructure.

## Considered options (optional)

What were the options that were considered?

* driver 1
* driver 2

## Decision

What decision was taken?

## Consequences

What are the consequences of this decision?
 