# Edge AI Accelerator

[![Build Status](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_apis/build/status%2FIaC%20for%20the%20Edge?branchName=main)](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_build/latest?definitionId=3&branchName=main)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)
[![Open in Dev Containers](https://img.shields.io/static/v1?label=Dev%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://dev.azure.com/ai-at-the-edge-flagship-accelerator/_git/edge-ai)

Production-ready Infrastructure as Code for edge AI solutions. Built by geeks, for geeks who need stuff that actually works in production.

## 🎯 Who This Is For

- **Platform Engineers** building edge AI infrastructure at scale
- **DevOps Teams** deploying IoT and edge computing solutions
- **Solution Architects** designing hybrid cloud-edge systems
- **Anyone** who's tired of edge infrastructure demos that don't work in the real world

## 🚀 Get Started (Pick Your Adventure)

### → [Just Want to Deploy Something?](docs/getting-started/general-user.md)

Start here if you want to deploy existing blueprints to Azure. **Time: 30-60 minutes**

### → [Building Custom Solutions?](docs/getting-started/blueprint-developer.md)

Start here if you're combining components into new deployment scenarios. **Time: 2-4 hours**

### → [Contributing New Features?](docs/getting-started/feature-developer.md)

Start here if you're developing new components or capabilities. **Time: 1-2 days setup**

## 📁 Repository Tour

```text
📦 edge-ai/
├── 📋 blueprints/          # Ready-to-deploy solution templates
├── 📚 docs/                # Complete documentation and guides
├── 🏗️  src/                # Reusable infrastructure components
├── 🧪 tests/               # Testing and validation
├── 🤖 scripts/             # Automation and utilities
└── 🚢 deploy/              # CI/CD pipelines and automation
```

### 🏗️ Infrastructure Components ([`src/`](src/))

Modular, reusable building blocks:

- **Cloud services** (identity, data, messaging, observability)
- **Edge platforms** (Kubernetes, Azure IoT Operations)
- **Application frameworks** (AI inference, telemetry)

### 📋 Deployment Blueprints ([`blueprints/`](blueprints/))

Complete solution templates:

- **Single-node edge** deployments
- **Multi-node cluster** setups
- **Cloud-only** configurations
- **Minimal** proof-of-concept setups

### 📚 Documentation ([`docs/`](docs/))

Everything you need to know:

- **Getting started** guides for different roles
- **Architecture** decisions and design patterns
- **Contributing** guidelines and development workflow

## 🛠️ Quick Setup (Dev Container Recommended)

**Prerequisites:** Docker, VS Code, and GitHub Copilot (seriously, this repo is optimized for AI-assisted development)

```bash
# Clone and open in VS Code
git clone https://github.com/Microsoft/edge-ai.git
cd edge-ai
code .

# When prompted, "Reopen in Container"
# Everything gets installed automatically 🎉
```

**Alternative:** [Manual setup instructions](docs/getting-started/development-environment.md) (for the brave)

## 🎨 What Makes This Different

- **Actually works in production** (not just pretty demos)
- **Modular design** - compose your own solutions
- **AI-assisted development** - optimized for GitHub Copilot
- **Multiple IaC frameworks** - Terraform today, Bicep coming soon
- **Comprehensive testing** - because edge infrastructure is hard enough

## 🤝 Contributing

We ❤️ contributions! Whether you're fixing typos or adding new components:

1. Read our [Contributing Guide](docs/contributing/)
2. Check out [open issues](https://github.com/Microsoft/edge-ai/issues)
3. Join the [discussion](https://github.com/Microsoft/edge-ai/discussions)

## 📄 Legal

This project is licensed under the [MIT License](./LICENSE).

**Security:** See [SECURITY.md](./SECURITY.md) for security policy and reporting vulnerabilities.

## Trademark Notice

> This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
> trademarks or logos is subject to and must follow Microsoft's Trademark & Brand Guidelines. Use of Microsoft trademarks or logos in
> modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or
> logos are subject to those third-party's policies.
