# Architecture Decision Record: Policy as Code with OPA Gatekeeper

Date: 2024-12-06

## Status

[Use the appropriate status to represent this decision record]

- [ ] Draft
- [x] Proposed
- [ ] Accepted
- [ ] Deprecated
- [ ] Superseded by 0002

## Context

Which Kubernetes Policy-as-Code tooling will be used to implement policy management to control inbound traffic on the cluster?
Our main security constraint in PSNet is to prevent the Azure ARC Agents Pods from committing to the cluster's state. Then, we need to implement strict pod isolation controls in our Kubernetes clusters to prevent unauthorized modifications from specific pods.

## Decision

We will implement pod isolation controls using OPA Gatekeeper instead of developing custom admission webhook controllers in Golang. This decision is particularly compelling given the significant effort required to develop and maintain a Golang-based solution. Gatekeeper's declarative approach aligns with our existing artifacts and provides a more sustainable path forward.

## Decision drivers

- Kubernetes policy requires:
  - Implementation of admission and mutation controls at cluster level to enforce security policies

- The solution must provide:
  - Capability to be maintainable and auditable
  - Scalability across multiple clusters
  - Reducing operational overhead

## Considered options

1. Custom Admission Webhooks in Golang

   - Requires developing dedicated admission webhook controllers in Golang
   - Requires upskilling in Golang development
   - Requires setting up new development processes and dedicated CI/CD pipelines
   - Requires implementation of logging, monitoring, and maintenance procedures
   - Dependency on Golang expertise for long-term maintenance

2. OPA Gatekeeper with Declarative Policies

   - Implementation through declarative YAML-based policy definitions, aligning with our existing infrastructure-as-code artifacts
   - Policy enforcement using Rego language: programming language built for policy expression
   - Utilization of existing constraint templates from OPA community
   - Built-in audit logging and monitoring capabilities
   - Native integration with Kubernetes admission controller framework
   - Automated certificate management and webhook lifecycle handling
   - Regular updates and security patches managed by the OPA community

## Decision Conclusion

### Positive

The adoption of OPA Gatekeeper will provide several advantages:

- Aligns with our existing infrastructure-as-code practices
- Eliminates need for extensive Golang training and hiring
- Provides declarative policy management with version-controlled YAML manifests
- Reduces development and maintenance complexity
- Offers built-in audit logging and violation reporting
- Enables access to community-maintained policy libraries
- Ensures consistent policy enforcement across clusters

### Negative

We must address several challenges:

- Teams will need to learn the Rego policy language
- Complex rules may require new ways of thinking about policy enforcement
- Adding another component to our Kubernetes infrastructure increases complexity

### Mitigation

To address these challenges, we will:

- Do upskilling on Rego and Gatekeeper
- Start with simple policies and gradually increase complexity
- Leverage existing constraint templates where possible
- Create documentation for each policy implemented to facilitate maintenance

## References

- [Gatekeeper Installation Documentation](https://open-policy-agent.github.io/gatekeeper/website/docs/install)
- [Gatekeeper Policy Library](https://github.com/open-policy-agent/gatekeeper-library)
- [Gatekeeper Constraint Framework](https://open-policy-agent.github.io/gatekeeper/website/docs/howto)
- [Rego Language Documentation](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [Kubernetes Admission Controllers](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)
- [Kubernetes Dynamic Admission Control](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)
- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [CNCF OPA Project Overview](https://www.cncf.io/projects/open-policy-agent-opa/)
- [OPA Community and Ecosystem](https://www.openpolicyagent.org/docs/latest/ecosystem/)
