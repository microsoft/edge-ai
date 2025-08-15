# Setup a GitOps CI/CD Flow

This guide walks you through setting up a complete GitOps CI/CD flow using the Kalypso pattern.

## Prerequisites

Before starting, ensure you have:

- **GitHub CLI** (`gh`) installed and authenticated
- **Git** configured with user name and email
- **GitHub Personal Access Token** with required permissions (see below)
- **Azure Service Principal** credentials

### GitHub Token Permissions

Set the `TOKEN` environment variable with a GitHub personal access token having these permissions:

**Classic Token Scopes:**

- `repo`, `workflow`, `write:packages`, `delete:packages`, `read:org`, `delete_repo`

**Fine-grained Token Permissions:**

- Actions (R/W)
- Administration (R/W)
- Commit statuses (R/W)
- Contents (R/W)
- Metadata (RO)
- Pull requests (R/W)
- Secrets (R/W)
- Variables (R/W)
- Workflows (R/W)

```bash
export TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
```

### Azure Credentials

Set the `AZURE_CREDENTIALS_SP` environment variable with service principal credentials. The service principal must have at least the `Reader` role on the target deployment scope:

```bash
export AZURE_CREDENTIALS_SP='{"clientId":"...","clientSecret":"...","subscriptionId":"...","tenantId":"..."}'
```

## Application Manifest Templates

The GitOps flow generates Kubernetes manifests for each environment using templates. Your application source repository should contain Helm templates in a `/helm` folder.

### Helm Chart Structure

Your application should have a Helm chart structure like this:

```text
your-app/
├── helm/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── configmap.yaml
└── ...
```

**Example:** See the [Basic Inference Application Helm chart](../500-application/500-basic-inference/charts/) for a complete example.

### Alternative Templating

While Helm is recommended, you can use other templating approaches. If you choose a different method, update the [generate-manifests.sh](https://github.com/microsoft/kalypso/blob/main/.github/workflows/templates/utils/generate-manifests.sh) utility in your accelerator repository to generate manifests using your preferred approach.

## Bootstrap Repositories

Run the setup script to create the GitOps repository structure:

```bash
./setup.sh -o <github-org> -r <app-repo-name> -e <first-environment>
```

**Example:**

```bash
./setup.sh -o mycompany -r edge-inference-app -e dev
```

### What the Setup Script Does

The script creates a three-repository GitOps pattern:

1. **Source Repository** (`your-app`)
   - Contains application source code and Helm charts
   - Receives a PR with CI/CD workflows and utility scripts
   - Handles building and testing the application

2. **Config Repository** (`your-app-configs`)
   - Contains environment-specific configuration values
   - Has branches for each environment (dev, qa, prod)
   - Managed by the application development team

3. **GitOps Repository** (`your-app-gitops`)
   - Contains final Kubernetes manifests for deployment
   - Has branches for each environment
   - Monitored by Azure Arc Flux controllers for deployment

### Repository Setup Details

The setup script will:

- Create the GitOps repository (`<org>/<app>-gitops`) if it doesn't exist
- Create environment branches in the GitOps repository
- Add GitHub Actions workflows to the GitOps repository
- Configure necessary variables and secrets
- Create the Config repository (`<org>/<app>-configs`) if it doesn't exist
- Create environment branches in the Config repository
- Add GitHub Actions workflows to the Config repository
- Create a PR in the Source repository with CI/CD workflows

**Important:** Merge the `GitOps CD setup` PR into your source repository to complete the setup.

## Define Application Configurations

The `configs` repository contains application-specific configuration values for deployment targets across environments. These configurations are application-centric and determine behavior like:

- Logging levels
- Number of replicas
- Feature flags
- Localizations
- Resource requests

### Branches and Folders Structure

The folder structure in the `configs` repository is flexible and can have any desired depth to group deployment targets. Each environment branch contains its own folder structure for deployment targets.

**Structure within each environment branch:**

```text
dev branch (configs-repo):
└── basic-inference/
    ├── functional-testing/
    │   └── values.yaml
    └── performance-testing/
        └── values.yaml

qa branch (configs-repo):
└── basic-inference/
    └── values.yaml

prod branch (configs-repo):
└── basic-inference/
    ├── amd/
    │   └── values.yaml
    └── arm/
        └── values.yaml
```

### Configuration Examples

**Development Environment - Functional Testing:**

```yaml
# dev/basic-inference/functional-testing/values.yaml
app:
  name: basic-inference-functional
  logLevel: debug
  enableTelemetry: true
replicas: 1
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
```

**Development Environment - Performance Testing:**

```yaml
# dev/basic-inference/performance-testing/values.yaml
app:
  name: basic-inference-performance
  logLevel: info
  enableTelemetry: true
replicas: 3
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

**Production Environment - AMD Architecture:**

```yaml
# prod/basic-inference/amd/values.yaml
app:
  name: basic-inference-prod
  logLevel: warn
  enableTelemetry: false
replicas: 5
nodeSelector:
  kubernetes.io/arch: amd64
resources:
  limits:
    cpu: 2000m
    memory: 2Gi
  requests:
    cpu: 1000m
    memory: 1Gi
```

**QA Environment - Shared Configuration:**

```yaml
# qa/basic-inference/values.yaml
app:
  name: basic-inference-qa
  logLevel: info
  enableTelemetry: true
replicas: 3
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
```

### Default Values

If `values.yaml` files in the `configs` repository are empty, the default values from the source repository's Helm chart will be used to generate manifests.

## Add New Environments

To add a new environment to your application:

1. **Create Environment Branches**
   - Create branches with the environment name in both `configs` and `gitops` repositories
   - You can do this manually or by running the `setup.sh` script again with a new environment name

2. **Configure Application Values**
   - Create `<deployment-target>/values.yaml` files in the environment branch
   - Add environment-specific application values or leave empty for defaults

3. **Set Up Environment Chain**
   - Define a `NEXT_ENVIRONMENT` GitHub variable in the previous environment
   - This enables automatic promotion flow between environments

**Example:** To add a `staging` environment after `dev`:

1. Create `staging` branches in both repositories
2. Set `NEXT_ENVIRONMENT=staging` in the `dev` environment variables
3. Configure staging-specific values in the configs repository

## Next Steps

After setting up your GitOps flow:

1. **Customize Workflows** - Modify the imported workflows to match your needs
2. **Add Environments** - Set up additional environments like staging and production
3. **Test Deployments** - Verify the complete promotional flow works as expected

For a complete working example, see the [CI/CD setup for the Basic Inference application](basic-inference-cicd/README.md).
