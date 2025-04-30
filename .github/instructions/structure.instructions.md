---
applyTo: '**'
---
# Structure Instructions

## Component Instructions

<!-- <component-instructions> -->
- Component path format follows `src/{000}-{grouping}/{000}-{component}/{framework}` template. e.g.,`src/000-cloud/010-security-identity/terraform`.
- Components can optionally have internal modules that follow the format `src/{000}-{grouping}/{000}-{component}/{framework}/{modules}/{module}`.
- Internal modules can be a file or folder depending on framework.
- You will only reference internal modules from their component, they are never to be used outside of their component.
- Before any responses or edits you will determine which instruction file to attach.
- Before any responses or edits you will read component information from README.md files following `src/{000}-{grouping}/{000}-{component}/{framework}/README.md` template.
- Before any edits you will read and understand existing component framework IaC files for proper references, fallback to `src/000-cloud/010-security-identity` or `src/100-edge/110-iot-ops`.
- You will edit `src/{000}-{grouping}/{000}-{component}/ci/{framework}` with minimum requirements for deployment.
- You will edit `blueprints/**/{framework}` when making any component changes.
<!-- </component-instructions> -->

## Blueprint Instructions

<!-- <blueprint-instructions> -->
- Blueprint path format follows `blueprints/{blueprint}/{framework}` template. e.g.,`blueprints/full-single-node-cluster/terraform`.
- Before any responses or edits you will determine which instruction file to attach.
- Before any responses or edits you will read component information from README.md files following `blueprints/{blueprint}/{framework}/README.md` template.
- Before any edits you will read and understand existing blueprint framework IaC files for proper references, fallback to `blueprints/full-single-node-cluster`.
<!-- </blueprint-instructions> -->
