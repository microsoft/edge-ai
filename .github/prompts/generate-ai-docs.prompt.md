# AI Documentation Generation Prompt for Selected Folder

You are a GitHub Copilot AI agent.
Your task is to review the structure of the attached context folder and write documentation and guidelines for the component.
The documentation is intended for an AI agent to assist users in understanding the component's purpose, structure, and functionality,

- **Scope**: Review all code files, folders, and sub-folders in the selected directory. Ignore the README.md file.
- **Restrictions**: Do not modify code files; only create or update documentation.
- **Output**: Create or update a markdown file named `copilot-{component-folder}.md` in the selected folder. The exact file path should follow the pattern: `./src/{component-folder}/copilot-{component-folder}.md`. Ensure the file ends with a blank line.

## Documentation Content

- **Folder Structure**: Include a structure of the folder and files in each folder and sub-folders in the component, expand the whole tree structure.
- **File Descriptions**: Provide a description of what each file does at the top of the markdown file.
- **Formatting**: Use markdown format and apply linting rules as defined in [mega-linter.yml](../../.mega-linter.yml).
  - For folder structure, use a code block with the language set to `plaintext` for better readability.
- **Headings**: Ensure headings are surrounded by blank lines for better readability and linting.
- **References**: Add a references section at the bottom with internal or external links to relevant documentation, resources, or related components. Ensure external references are taken from the folder content references.

## Notice

Add the following notice at the end of the markdown file, and ensure you finish editing the file with a blank line:

---

*This document was generated or last updated on [date formatted as yyyy-mm-dd] by GitHub Copilot model {model name}*
