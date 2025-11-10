---
title: 'Kata: 200 - Token-Efficient Context Strategies'
description: Learn efficient token usage, minimize verbose context, and build precise prompting patterns for optimal AI assistance
author: microsoft/edge-ai
ms.date: 10/25/2025

kata_id: ai-assisted-engineering-200-token-efficient-context
kata_category:
  - ai-assisted-engineering
kata_difficulty: 2
estimated_time_minutes: 30

learning_objectives:
  - Understand token usage and context efficiency concepts
  - Provide precise, minimal context for AI assistance
  - Avoid verbose or redundant context inclusion
  - Build token-efficient prompting and reference patterns

prerequisite_katas:
  - ai-assisted-engineering-100-conversation-checkpoint-restore
  - ai-assisted-engineering-100-conversation-clearing-strategy

technologies:
  - GitHub Copilot Chat
  - VS Code

success_criteria:
  - Craft token-efficient prompts with precise context
  - Use @workspace and #file references effectively
  - Eliminate redundant context from conversations
  - Maintain effectiveness while reducing token usage

ai_coaching_level: guided
scaffolding_level: medium-heavy
hint_strategy: progressive

common_pitfalls:
  - Including entire files when only small sections are needed
  - Repeating context already available through workspace awareness
  - Over-explaining when precise references would suffice
  - Not leveraging @workspace or #file references efficiently

requires_azure_subscription: false
requires_local_environment: true

tags:
  - ai-assisted-engineering

search_keywords:
  - token usage
  - efficient prompting
  - context optimization
  - github copilot references
---

## Quick Context

**You'll Learn**: How to craft token-efficient prompts, leverage @workspace and #file references, and maintain high-quality AI assistance while minimizing context overhead.

**Real Challenge**: You're a lead developer working on a microservices platform with 50+ files. You need AI help refactoring an authentication module, but you're hitting token limits because you've been pasting entire files into conversations. Your prompts are verbose, repeating information the AI already has access to through workspace awareness. You need to optimize context usage without losing effectiveness.

**Your Task**: Learn token-efficient context strategies to extend conversation capacity, improve response quality, and maintain productivity across complex codebases.

## Essential Setup

**Required** (check these first):

- [ ] VS Code with GitHub Copilot extension enabled and Chat panel accessible
- [ ] Workspace with multiple code files (use current project or clone sample repository)
- [ ] Completion of Conversation Checkpoint Restore and Conversation Clearing Strategy katas (prerequisites)
- [ ] Time allocated: 30 minutes for token-efficient prompting practice

**Quick Validation**: Open GitHub Copilot Chat, type `@workspace` and verify workspace-aware suggestions appear.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** chat mode for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** mode and say:
>
> ```text
> I'm working on Token-Efficient Context Strategies kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Understanding Token Efficiency (10 minutes)

<!-- AI_COACH: Before diving into techniques, build intuition about token economy. Ask: "Why would including less context sometimes produce better AI responses? What's the relationship between context volume and response quality?" Guide learners to discover the quality-efficiency balance. -->

**What You'll Do**: Learn token economy principles and recognize verbose versus efficient context patterns.

**Steps**:

1. **Learn** token usage concepts
   - [ ] Understand that every word in prompts and responses consumes tokens
   - [ ] Recognize that file content, code blocks, and explanations all count toward limits
   - [ ] Learn that token budgets are shared between input (your prompt) and output (AI response)
   - **Pro tip**: If your prompt uses 90% of available tokens, the AI has only 10% left for its response
   - [ ] **Expected result**: Clear understanding of token allocation trade-offs

2. **Compare** verbose versus efficient context examples
   - [ ] Review the comparison table below
   - [ ] Identify patterns that waste tokens without adding value
   - [ ] Recognize how references replace repetition
   - **Validation checkpoint**: Why is "precise reference + question" more efficient than "full code paste + question"?
   - [ ] **Expected result**: Ability to spot inefficient context patterns

   **Verbose vs. Efficient Context Comparison**:

   | Verbose Pattern                                                  | Token Cost | Efficient Alternative                                                   | Token Cost | Improvement    |
   |------------------------------------------------------------------|------------|-------------------------------------------------------------------------|------------|----------------|
   | Paste entire 500-line file                                       | ~2500      | Reference specific function with `#file:path:lineStart-lineEnd`         | ~100       | 96% reduction  |
   | "Explain all the files in src/"                                  | ~5000+     | `@workspace what's the purpose of the authentication module?`           | ~50        | 99% reduction  |
   | Re-explain previous context                                      | ~300       | Continue conversation (AI remembers)                                    | ~0         | 100% reduction |
   | Paste error + stack + logs                                       | ~1000      | Paste error message only, reference file with `#file`                   | ~150       | 85% reduction  |
   | "I'm working on feature X, which connects to Y, depends on Z..." | ~200       | `@workspace how does #file:feature-x.ts integrate with the auth layer?` | ~40        | 80% reduction  |

3. **Practice** minimal viable context selection
   - [ ] Take a current coding question you have
   - [ ] Write it out with all the context you'd normally include
   - [ ] Remove half the context and ask if the question is still clear
   - [ ] Remove half again and reassess
   - [ ] Find the minimum context that preserves question quality
   - **Success criteria**: Your refined question is 30-50% shorter but still answerable
   - [ ] **Expected result**: Intuition for minimal viable context

### Task 2: Precision Context Techniques (12 minutes)

<!-- AI_COACH: Guide discovery of reference features through experimentation. Ask: "What happens when you type @ or # in Copilot Chat? What suggestions appear? Try different combinations and observe what the AI understands." -->

**What You'll Do**: Learn @workspace and #file references to provide targeted context efficiently.

**Steps**:

1. **Learn** @workspace references
   - [ ] Type `@workspace` in GitHub Copilot Chat to see available commands
   - [ ] Practice: `@workspace what files handle database connections?`
   - [ ] Practice: `@workspace explain the deployment architecture`
   - [ ] Understand that @workspace gives AI access to entire codebase without pasting
   - **Pro tip**: @workspace is best for broad questions about code organization, patterns, or architecture
   - [ ] **Expected result**: Comfortable using @workspace for codebase-wide queries

2. **Learn** #file references for precision
   - [ ] Type `#file` in GitHub Copilot Chat to see file picker
   - [ ] Practice: `#file:src/auth/login.ts explain the token validation logic`
   - [ ] Practice: Reference specific line ranges when available
   - [ ] Understand that #file provides focused context without full file paste
   - **Validation checkpoint**: When would you use #file instead of @workspace?
   - [ ] **Expected result**: Efficient file referencing for targeted questions

   **Reference Syntax Quick Guide**:

   ```text
   @workspace [question about codebase]
     ↳ Workspace-wide context, best for architectural or organizational questions

   #file:path/to/file.ext [question about specific file]
     ↳ Single-file context, best for implementation details or specific logic

   #file:path/to/file.ext:10-25 [question about specific lines]
     ↳ Line-range context, most precise and token-efficient
   ```

   **Alt Text for Reference Guide**: Reference syntax examples showing @workspace for codebase-wide questions, #file for single-file context, and #file with line ranges for maximum precision.

3. **Eliminate** redundant context
   - [ ] Before each prompt, ask: "Does the AI already know this from workspace awareness?"
   - [ ] Avoid re-explaining project structure—@workspace provides this
   - [ ] Skip pasting code the AI can access via #file
   - [ ] Remove background information if continuing a conversation (AI remembers)
   - **Pro tip**: Think "reference, don't repeat"—point to context rather than duplicating it
   - [ ] **Expected result**: Prompts that are 50-70% shorter without losing clarity

   <!-- AI_COACH: If learner struggles with eliminating redundancy, ask: "What information have you already mentioned in this conversation? What can the AI infer from workspace context? Challenge yourself to remove half of your context—is the question still answerable?" -->

### Task 3: Advanced Context Optimization (8 minutes)

<!-- AI_COACH: Build on previous techniques with layering strategies. Ask: "How could you structure a series of questions to build understanding incrementally, rather than front-loading all context in one prompt?" -->

**What You'll Do**: Develop advanced patterns for context layering and efficient follow-up conversations.

**Steps**:

1. **Build** reference-based context patterns
   - [ ] Start broad: Use @workspace to establish understanding
   - [ ] Narrow focus: Use #file to dive into specifics
   - [ ] Target precisely: Reference line ranges for exact context
   - [ ] Chain references: Combine @workspace and #file in single prompts when needed
   - **Pro tip**: Think of references as zoom levels—workspace is satellite view, file is street view, line range is ground level
   - [ ] **Expected result**: Multi-level context referencing strategy

   **Context Layering Example**:

   ```text
   1. Establish broad understanding:
      @workspace what's the authentication flow?

   2. Dive into specifics:
      #file:src/auth/jwt-handler.ts how does token refresh work?

   3. Target exact implementation:
      #file:src/auth/jwt-handler.ts:45-67 why is this refresh logic using a 5-minute buffer?

   Result: Progressive context building with minimal token overhead
   ```

2. **Practice** efficient follow-up patterns
   - [ ] Leverage conversation memory: Don't repeat prior context
   - [ ] Ask targeted follow-ups: "What about the error case?" instead of re-explaining
   - [ ] Build incrementally: Each question adds one layer, not a new foundation
   - [ ] Reference previous AI responses: "In the solution you suggested, how would..."
   - **Validation checkpoint**: How does incremental questioning compare to one large prompt in token efficiency?
   - [ ] **Expected result**: Conversation flow that builds understanding without redundancy

   <!-- AI_COACH: Challenge with optimization scenario: "You need to refactor a 10-file feature. How would you structure the conversation to cover all files efficiently? Compare your approach to someone who pastes all 10 files at once." -->

3. **Develop** personal optimization workflow
   - [ ] Before prompting, ask: "What's the minimum context needed?"
   - [ ] Choose reference type: @workspace for broad, #file for specific
   - [ ] Check conversation history: Am I repeating myself?
   - [ ] Refine iteratively: Start minimal, add context only if AI asks
   - **Success criteria**: Average prompt uses 60-70% fewer tokens than before this kata
   - [ ] **Expected result**: Automatic, efficient context selection in all AI interactions

## Completion Check

**You've Succeeded When**:

- [ ] You craft token-efficient prompts using precise context references
- [ ] You use @workspace and #file references effectively for different query types
- [ ] You eliminate redundant context and repetition from conversations
- [ ] You maintain AI assistance quality while significantly reducing token usage

**Next Steps**: Apply these strategies to your daily development workflow. Monitor how much longer your conversations remain productive before hitting token limits.

---

## Reference Appendix

### Help Resources

- **GitHub Copilot Chat**: Primary interface for @workspace and #file references
- **VS Code**: Workspace awareness enables efficient context references
- **Conversation Clearing Strategy Kata**: Reference for proactive conversation management

### Professional Tips

- "Reference, don't repeat"—point to context rather than duplicating it
- Think of references as zoom levels: @workspace (satellite), #file (street), line range (ground)
- If your prompt uses 90% of tokens, the AI has only 10% left for response
- Start minimal, add context only if AI asks—let AI request what it needs
- Average token efficiency should improve 60-70% after learning these techniques

### Troubleshooting

**Issue**: AI says it doesn't have access to referenced file

- **Quick Fix**: Ensure file is in current workspace. Try opening the file in VS Code first, then reference it.

**Issue**: @workspace returns too broad results

- **Quick Fix**: Add more specific keywords to your question. Example: Instead of `@workspace explain authentication`, use `@workspace how does JWT token refresh work in the auth module?`

**Issue**: Not sure whether to use @workspace or #file

- **Quick Fix**: Use @workspace for architecture, patterns, or finding files. Use #file when you know the specific file and need implementation details.

**Issue**: Prompts still feel long and verbose

- **Quick Fix**: Challenge yourself: Remove half your context. Still answerable? Remove half again. Find the minimum that works.

**Issue**: AI asking for context I thought it had

- **Quick Fix**: The AI might not infer as much as expected. Provide targeted context using #file, but keep it minimal.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
