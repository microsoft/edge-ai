# ADR Title

Date: **2024-11-07** [Format=YYYY-MM-DD]

## Status

[Use the appropriate status to represent this decision record]

- [ ] Draft
- [ ] Proposed
- [x] Accepted
- [ ] Deprecated
- [ ] Superseded by 0002

## Decision

Which Kubernetes options will be supported in this accelerator for cloud-hosted development/test/lab clusters?

## Context

Customers need to enable collaborative development with Kubernetes clusters hosted in cloud environments.

## Decision drivers

- Cloud hosted clusters that must be as close to production environments as possible:
  - Lightweight
  - Run on Ubuntu x86/x64 
  - Certified/CNCF Compliant

## Considered options

1. K3s - Lightweight certified Kubernetes distribution
    - Good, great for development use cases
    - Good, designed for resource restricted environments 
    - Good, requires the least amount of memory: 512 MB
    - Good, supported platform for GA of AIO

1. Kubernetes in Docker (KinD)
    - Good, great for development and is widely used to test Kubernetes itself
    - Bad, kubernetes nodes run in docker and does not resemble real environments
    - Bad, still a work in progress to v1.0
    - Bad, unsupported platform for GA of AIO

1. MicroK8s - minimal Kubernetes
    - Good, great for development use cases
    - Good, designed for resource restricted environments
    - Good, requires a small amount of memory: 540 MB
    - Bad, unsupported platform for GA of AIO

1. Minikube  
    - Good, built for development use cases
    - Bad, not great for resource constrained environments: 2 GB of free memory
    - Bad, unsupported platform for GA of AIO

## Decision Conclusion

K3s on Ubuntu VMs as it's the only supported platform for GA.

## Consequences

We're only meeting about 25% of customers where they are. 
