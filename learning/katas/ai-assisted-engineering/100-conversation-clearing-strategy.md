---
title: 'Kata: 100 - Conversation Clearing Strategy'
description: Learn when to clear conversations, manage VS Code conversation history limits, and maintain efficient context boundaries
author: microsoft/edge-ai
ms.date: 10/25/2025

kata_id: ai-assisted-engineering-100-conversation-clearing-strategy
kata_category:
  - ai-assisted-engineering
kata_difficulty: 1
estimated_time_minutes: 25

learning_objectives:
  - Recognize VS Code conversation limits and token warnings
  - Understand when to clear versus continue conversations
  - Identify logical task boundaries for conversation management
  - Implement proactive context boundary management

prerequisite_katas:
  - ai-assisted-engineering-100-conversation-checkpoint-restore

technologies:
  - GitHub Copilot Chat
  - VS Code

success_criteria:
  - Identify warning signs of approaching context limits
  - Apply clear versus continue decision framework
  - Recognize logical task boundaries for clearing
  - Apply proactive context boundary management

ai_coaching_level: guided
scaffolding_level: heavy
hint_strategy: progressive

common_pitfalls:
  - Clearing mid-task when checkpoint restore would preserve context
  - Waiting too long and hitting hard token limits
  - Not recognizing logical task boundaries for clearing

requires_azure_subscription: false
requires_local_environment: true

tags:
  - ai-assisted-engineering

search_keywords:
  - conversation clearing
  - token limits
  - context boundaries
  - github copilot chat
---

## Quick Context

**You'll Learn**: How to recognize VS Code conversation limits, apply strategic conversation clearing at task boundaries, and maintain efficient context management throughout development sessions.

**Real Challenge**: You're a senior developer reviewing microservices architecture across multiple services. After a long debugging session spanning authentication, data layer, and API gateway issues, you suddenly see a "summarizing conversation history" warning. Response quality is degrading and suggestions are less relevant. You need to decide when to clear versus when to continue.

**Your Task**: Learn conversation clearing strategy to maintain optimal AI assistance quality and avoid context limit issues before they impact your productivity.

## Essential Setup

**Required** (check these first):

- [ ] VS Code installed with GitHub Copilot extension enabled
- [ ] GitHub Copilot Chat panel accessible
- [ ] Completion of Conversation Checkpoint Restore kata (recommended)

**Quick Validation**: Run a conversation with GitHub Copilot Chat and verify you can see the new conversation button to clear history.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** chat mode for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** mode and say:
>
> ```text
> I'm working on Conversation Clearing Strategy kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Recognize Context Limits (10 minutes)

<!-- AI_COACH: Before explaining limits, ask: "Have you noticed the AI's responses getting less relevant in long conversations? What might cause that degradation?" Help learners discover token concepts before providing technical details. -->

**What You'll Do**: Learn to recognize VS Code conversation limits and understand token constraint concepts.

**Steps**:

1. **Understand** VS Code conversation limits
   - [ ] Learn that VS Code Copilot conversations have limits (~100 messages or ~25,000 tokens)
   - [ ] Recognize that longer conversations consume more token budget
   - [ ] Understand that token limits protect against context window overflow
   - **Pro tip**: Token count includes both your messages and AI responses, plus any file context
   - [ ] **Expected result**: Clear understanding of conversation capacity constraints

2. **Identify** the "summarizing conversation history" warning
   - [ ] Learn what the warning looks like in GitHub Copilot Chat
   - [ ] Recognize this appears when approaching token limits
   - [ ] Understand that summarization degrades context quality
   - **Validation checkpoint**: Why would summarization reduce response quality?
   - [ ] **Expected result**: Can spot the warning before it impacts work

   **Token Limit Warning Example**:

   ```text
   ┌─────────────────────────────────────────────────────┐
   │  ⚠️  Summarizing conversation history to manage     │
   │     token limits. Consider starting a new           │
   │     conversation for optimal context.               │
   └─────────────────────────────────────────────────────┘
   ```

   **Alt Text for Warning**: GitHub Copilot Chat warning message indicating conversation history is being summarized due to approaching token limits, with suggestion to start new conversation.

3. **Learn** context window concepts
   - [ ] Understand that AI models have finite context windows
   - [ ] Recognize that exceeding limits causes information loss
   - [ ] Learn that proactive clearing prevents degradation
   - **Pro tip**: Think of context windows like RAM—limited capacity requiring strategic management
   - [ ] **Expected result**: Mental model of how context limits work

### Task 2: Strategic Conversation Clearing (10 minutes)

<!-- AI_COACH: Challenge learner to think about task boundaries before providing the table. Ask: "What moments in your development workflow represent natural breakpoints? When would starting fresh make more sense than continuing?" -->

**What You'll Do**: Develop judgment for when to clear conversations versus continuing with current context.

**Steps**:

1. **Review** clear versus continue decision factors
   - [ ] Study the decision factors table below
   - [ ] Understand the trade-offs between clearing and continuing
   - [ ] Recognize warning signs requiring clearing
   - **Validation checkpoint**: Can you identify 3 scenarios where clearing is better than continuing?
   - [ ] **Expected result**: Decision framework for clearing versus continuing

   **Clear vs. Continue Decision Table**:

   | Scenario                                       | Clear? | Rationale                                 |   |
   |------------------------------------------------|--------|-------------------------------------------|---|
   | Token limit warning appears                    | ✅ Yes  | Prevent context degradation and loss      |   |
   | Completed feature implementation               | ✅ Yes  | Natural task boundary, new context needed |   |
   | Switching from debugging to new feature        | ✅ Yes  | Different context requirements            |   |
   | Mid-function debugging, found root cause       | ❌ No   | Preserve investigation context            |   |
   | Asking clarifying questions about current code | ❌ No   | Context is directly relevant              |   |
   | Planning next steps for current task           | ❌ No   | Builds on existing conversation           |   |
   | Context drift detected mid-task                | ❌ No   | Use restore checkpoint instead            |   |
   | Completed all sprint stories                   | ✅ Yes  | Major boundary, fresh start appropriate   |   |

2. **Practice** identifying task boundaries
   - [ ] Recognize completion signals: tests pass, feature deployed, PR merged
   - [ ] Identify transition points: switching components, changing languages, new ticket
   - [ ] Understand continuation signals: follow-up questions, iterative refinement, same codebase
   - **Pro tip**: Clear at major boundaries (features, PRs), restore at minor drift (mid-task confusion)
   - [ ] **Expected result**: Intuitive sense of when to clear

   <!-- AI_COACH: If learner struggles with boundary identification, ask: "Would you explain this context to a new team member joining the conversation? If yes, clearing makes sense. If no, continue." -->

3. **Apply** clearing at logical boundaries
   - [ ] Practice clearing after completing a function and its tests
   - [ ] Try clearing when switching between infrastructure and application code
   - [ ] Test continuing when iterating on the same implementation
   - **Success criteria**: Clearing feels natural at task completion points
   - [ ] **Expected result**: Confident clearing decisions in real workflows

### Task 3: Proactive Context Management (5 minutes)

<!-- AI_COACH: Guide learners to build prevention habits rather than reactive responses. Ask: "How could you structure your work sessions to avoid hitting limits? What patterns would prevent the need for emergency clearing?" -->

**What You'll Do**: Build proactive strategies to prevent context limit issues before they occur.

**Steps**:

1. **Develop** conversation scoping habits
   - [ ] Scope conversations to single features or components
   - [ ] Plan to clear between distinct development phases
   - [ ] Avoid mixing unrelated contexts in one conversation
   - **Pro tip**: Start each morning or major task with a fresh conversation
   - [ ] **Expected result**: Proactive conversation management mindset

2. **Build** efficient conversation patterns
   - [ ] Keep exchanges focused and relevant to current task
   - [ ] Avoid including unnecessary file context
   - [ ] Ask targeted questions rather than broad exploratory ones
   - **Validation checkpoint**: How does focused questioning help manage token budget?
   - [ ] **Expected result**: More efficient token usage patterns

3. **Create** personal clearing workflow
   - [ ] Establish clearing triggers: after PR, after deployment, after test suite passes
   - [ ] Build a habit: check conversation length before major context switches
   - [ ] Develop intuition: "This feels like a new conversation" signals clearing time
   - **Success criteria**: Rarely see token limit warnings due to proactive management
   - [ ] **Expected result**: Smooth, uninterrupted development flow with optimal AI assistance

## Completion Check

**You've Succeeded When**:

- [ ] You can identify warning signs of approaching context limits
- [ ] You apply the clear versus continue decision framework appropriately
- [ ] You recognize logical task boundaries for conversation clearing
- [ ] You maintain productive context boundaries through proactive management

**Next Steps**: Continue to [Token-Efficient Context Strategies](200-token-efficient-context.md) to learn advanced techniques for minimizing token usage while maintaining effective AI assistance.

---

## Reference Appendix

### Help Resources

- **GitHub Copilot Chat**: Primary interface for conversation management
- **VS Code**: Token limit warnings appear in chat interface
- **Conversation Checkpoint Restore Kata**: Reference for when to restore vs. clear

### Professional Tips

- Clear at major boundaries (features, PRs), restore at minor drift (mid-task confusion)
- Token count includes your messages, AI responses, and file context
- Think of context windows like RAM—limited capacity requiring strategic management
- Proactive clearing prevents degradation better than reactive responses
- Start each major task with a fresh conversation for optimal context

### Troubleshooting

**Issue**: Seeing token limit warnings frequently

- **Quick Fix**: Scope conversations more narrowly to single features or components. Clear between distinct development phases.

**Issue**: Unclear whether to clear or restore checkpoint

- **Quick Fix**: Use this rule: Clear at task boundaries or token warnings. Restore for mid-task context drift.

**Issue**: Lost important context after clearing

- **Quick Fix**: Document key decisions before clearing. Use code comments or notes to preserve critical context that spans conversations.

**Issue**: Responses degrading but no warning yet

- **Quick Fix**: Long conversations naturally degrade. If you notice quality dropping, clear proactively—don't wait for the warning.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
