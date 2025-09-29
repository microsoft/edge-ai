---
mode: 'agent'
description: 'Generates a commit message following the commit-message.instructions.md rules based on all changes in the branch'
---

# Generate Commit Message

Must follow all instructions provided by #file:../instructions/commit-message.instructions.md
* Use the get_changed_files tool to get the staged changes and build a commit message based on the staged git diff.
* Output to the user an appropriate commit message based on these changes in-between a markdown codeblock.
* Inform the user that they should copy it as-is or modify it and use it for their commit message.

---

Proceed generating the commit message
