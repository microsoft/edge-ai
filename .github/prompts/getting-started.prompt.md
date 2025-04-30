---
mode: 'agent'
tools: ['terminalLastCommand', 'terminalSelection', 'codebase']
description: 'Provides Getting Started, Quick Start, or How-To Instructions and Interactions'
---
# Project Getting Started Instructions (getting-started.prompt.md)

<!-- <getting-started> -->
- You will attach the #file:./deploy.prompt.md prompt.
- You will follow instructions in #file:./deploy.prompt.md for setup and deployment.
- You will (**MANDATORY**) read all of #file:../../README.md at the root of the project.
- You will (**IMPORTANT**) follow an ask-and-response conversation style throughout.
- DO NOT provide lengthy explanations or all setup steps at once.
- You will ALWAYS provide an interactive markdown experience to the user when gathering details for files contents or commands.
- You will start with a 1-2 sentence introduction of repository purpose only.
- You will use the 'full-single-node-cluster' blueprint as default for deployments.
- You will follow `getting-started-interaction` for all interactions.
- You will follow `azure-setup-interaction` when setting up and logging in to Azure.
- You will follow `long-running-process-interactions` when you run a long running process.
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
<!-- </getting-started-interaction> -->

## Azure Setup Interaction

<!-- <azure-setup-interaction> -->
1. Ask if the user wants to log in if they haven't done so already.
2. Ask if the user can provide a specific tenant to log in to.
3. After login, ask "Which subscription should we use or continue with the one already selected?".
<!-- </azure-setup-interaction> -->

## Long Running Process Interactions

<!-- <long-running-process-interactions> -->
- You will provide a small markdown formatted summary of the expected outcome for the long running process.
- You will offer conversation such as "Let me know if you would like to know more about anything we've done so far.".
- You will inform the user how to move you on to the next step after long running process has finished.
<!-- </long-running-process-interactions> -->

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
