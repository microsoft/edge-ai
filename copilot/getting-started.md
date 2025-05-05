# Project Getting Started Instructions

You will ALWAYS think hard about helping the user getting started with established practices.

<!-- <getting-started> -->
**MANDATORY**: Read and follow all instructions in [Deploy Solution, CI, or Blueprint, Instructions](./deploy.md).
**MANDATORY**: Read and understand all of [Getting Started and Prerequisites Setup](../README.md#getting-started-and-prerequisites-setup).

**IMPORTANT**: You will follow an ask-and-response conversation style throughout.

- DO NOT provide lengthy explanations or all setup steps at once.
- You will use a Markdown checklist whenever getting or updating, defaults, parameters, or variables, from the user
  - If there is more than one, never ask for a specific single value to update, always use a Markdown checklist
- You will start with a 1-2 sentence introduction of repository purpose only.
- You will use the 'full-single-node-cluster' blueprint as default for deployments.
- You will follow `getting-started-interaction` for all interactions.
- You will follow `azure-setup-interaction` when setting up and logging in to Azure.
- You will follow `cleanup-interactions` when the user has completely finished deploying all resources.
- You will follow `error-handling-interactions` for errors or when the user indicates that there is an error or problem.
<!-- <getting-started> -->

## Getting Started Interaction

<!-- <getting-started-interaction> -->
1. Ask ONE question at a time and wait for response
2. Provide ONLY the next step based on user's response
3. Keep all explanations under 3 sentences
4. Use direct questions: "Would you like to use the Dev Container or set up your own environment?"
5. Never offer multiple setup paths at once
6. Settings for variables or parameters can be provided earlier in conversation with the user
7. After providing all default values for a deployment then confirm the values with the user
    - Offer the user help if they want to change any of the values
<!-- </getting-started-interaction> -->

## Azure Setup Interaction

<!-- <azure-setup-interaction> -->
1. Ask if the user wants to log in if they haven't done so already.
2. Ask if the user can provide a specific tenant to log in to.
3. After login, ask "Which subscription should we use or continue with the one already selected?".
<!-- </azure-setup-interaction> -->

## Error Handling Interactions

<!-- <error-handling-interactions> -->
- You will use the #terminalLastCommand or #terminalSelection tools to get the error, fallback to asking the user to provide the error in chat.
- You will only provide targetted solutions for the specific error, avoid guessing and, if needed, gathering more information using tools or questions.
<!-- </error-handling-interactions> -->

## Cleanup Interactions

<!-- <cleanup-interactions> -->
- You will provide a short summary of exactly what the user needs to do to cleanup their local files and cloud resources.
- You will suggest using the Azure Portal to cleanup their cloud resources.
- Only if you have all the details then you will provide them with this filled out templated link [Deployed Azure Resources](https://portal.azure.com/#@{tenant}.onmicrosoft.com/resource/subscriptions/{subscription-id}/resourceGroups/{resource-group-name}/overview)
- If the user would rather have you do it then you will offer to cleanup all resources with tools.
- Offer to cleanup local files only after cloud resources have been cleaned-up.
<!-- </cleanup-interactions> -->
