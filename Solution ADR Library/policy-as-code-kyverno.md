# Architecture Decision Record: Policy as Code with Kyverno

Date: 2024-12-06

## Status

[Use the appropriate status to represent this decision record]

- [ ] Draft
- [x] Proposed
- [ ] Accepted
- [ ] Deprecated
- [ ] Superseded by 0002

## Context

Which Kubernetes Policy-as-Code tooling will be used to implement policy management on the cluster?
We identified the need for Kubernetes policy management and pod security controls across our clusters.

## Decision

**Kyverno** can be implemented for Kubernetes policy management. Its YAML-based approach aligns with the team's expertise and existing IaC strategy, while its advanced features surpass Gatekeeper's capabilities. This choice accelerates implementation, simplifies maintenance, and reduces training overhead as well.

## Decision drivers

- Kubernetes policy management must enforce:
  - Admission controls
  - Validation of resources
  - Mutation of configurations

- The solution must be accessible to the team

- The solution must provide:
  - Robust policy enforcement
  - Minimizing the learning curve
  - Reducing operational complexity

## Considered options

### 1. **OPA Gatekeeper**

- **Strengths**:
  - Robust policy enforcement.
  - CNCF graduated project with strong community support.
- **Limitations**:
  - Requires learning Rego, a domain-specific language.
  - Separate steps for policy and constraint definitions.
  - Limited native resource generation and management capabilities.

### 2. **Kyverno**

- **Strengths**:
  - Policies defined in YAML, aligning with the existing IaC strategy.
  - Advanced features: image verification, resource generation, encryption of sensitive data.
  - Single-step policy definition simplifies management.
  - Native integration with Kubernetes resources.
  - Built-in policy reporting, background scanning, and mutation capabilities.
- **Limitations**:
  - Smaller community compared to Gatekeeper.
  - Less historical production usage.
  - Fewer pre-existing policy libraries.

## Decision Conclusion

### Positive

- Productivity boost with familiar YAML syntax.
- Advanced capabilities (e.g., image verification, resource generation).
- Simplified policy lifecycle management.
- Native Kubernetes resource integration.
- Reduced training effort and compatibility with GitOps workflows.
- Comprehensive validation, mutation, and resource generation in a single policy.

### Negative

- Smaller community and newer project compared to Gatekeeper.
- Migration effort if existing policies are in place.
- Limited availability of pre-built policy libraries.

## References

- [Kyverno Official Documentation](https://kyverno.io/docs/)
- [Kyverno vs. OPA Gatekeeper Comparison](https://kyverno.io/docs/introduction/#comparison-to-other-policy-engines)
- [Kyverno Policy Examples](https://kyverno.io/policies/)
- [Kubernetes Admission Controllers](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)
- [Kyverno GitHub Repository](https://github.com/kyverno/kyverno)
- [Kyverno Policy Reports](https://kyverno.io/docs/policy-reports/)
- [Kyverno Image Verification](https://kyverno.io/docs/writing-policies/verify-images/)
- [CNCF Kyverno Project](https://www.cncf.io/projects/kyverno/)
