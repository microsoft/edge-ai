---
title: 'Kata: 100 - Conversation Checkpoint Restore'
description: Learn when and how to restore conversation checkpoints for efficient workflow recovery and context management
author: microsoft/edge-ai
ms.date: 10/25/2025

kata_id: ai-assisted-engineering-100-conversation-checkpoint-restore
kata_category:
  - ai-assisted-engineering
kata_difficulty: 1
estimated_time_minutes: 25

learning_objectives:
  - Identify context drift signals requiring checkpoint restore
  - Use the restore checkpoint feature to recover conversation state
  - Understand what is preserved versus cleared during restoration
  - Apply strategic checkpoint timing for workflow efficiency

prerequisite_katas: []

technologies:
  - GitHub Copilot Chat
  - VS Code

success_criteria:
  - Identify 3+ context drift signals
  - Successfully restore conversation checkpoint
  - Explain difference between restore checkpoint and clear conversation
  - Apply checkpoint strategies to maintain workflow efficiency

ai_coaching_level: guided
scaffolding_level: heavy
hint_strategy: progressive

common_pitfalls:
  - Using restore checkpoint when conversation should be cleared
  - Not recognizing context drift signals early enough
  - Confusing restore checkpoint with undo functionality

requires_azure_subscription: false
requires_local_environment: true

tags:
  - ai-assisted-engineering

search_keywords:
  - checkpoint restore
  - context drift
  - conversation recovery
  - github copilot chat
---

## Quick Context

**You'll Learn**: How to recognize context drift signals, use the restore checkpoint feature, and strategically manage conversation state for efficient AI-assisted development workflows.

**Real Challenge**: You're a senior developer working through complex Terraform debugging. After switching context to check Azure documentation and then planning next steps, GitHub Copilot's responses become confused—it's mixing information from different phases of your work. You need to restore to an earlier productive state without losing all your conversation history.

**Your Task**: Learn the restore checkpoint feature to recover from context drift and maintain productive AI collaboration throughout multi-phase development sessions.

## Essential Setup

**Required** (check these first):

- [ ] VS Code installed with GitHub Copilot extension enabled
- [ ] GitHub Copilot Chat panel accessible
- [ ] Active conversation with at least a few exchanges

**Quick Validation**: Open GitHub Copilot Chat and verify you can see the conversation history panel with previous messages.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on Conversation Checkpoint Restore kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Understand Context Drift (10 minutes)

<!-- AI_COACH: Help learners recognize context drift patterns before explaining restore mechanics. Ask: "Have you noticed the AI giving contradictory responses or forgetting earlier context? What patterns preceded those issues?" Guide them to discover the signals naturally. -->

**What You'll Do**: Learn to recognize the signals that indicate your conversation needs checkpoint restoration.

**Steps**:

1. **Identify** context drift patterns
   - [ ] Review the context drift signals table below
   - [ ] Compare signals to your own Copilot usage experiences
   - **Pro tip**: Context drift often happens after multiple topic switches or long conversations
   - [ ] **Expected result**: Understanding of what causes context drift

   **Context Drift Signals Table**:

   | Signal                          | Meaning                                    | Action                                     |
   |---------------------------------|--------------------------------------------|--------------------------------------------|
   | AI references wrong context     | Context drift from topic switching         | Restore checkpoint to productive state     |
   | "I don't have that information" | Lost context from earlier conversation     | Restore checkpoint before information loss |
   | Contradictory responses         | Confused state from conflicting inputs     | Restore checkpoint to clear state          |
   | Suggestions don't match task    | Topic confusion from rapid context changes | Restore checkpoint to relevant context     |
   | Repeated questions              | AI can't recall earlier decisions          | Restore checkpoint to decision point       |

2. **Practice** identifying drift in example scenarios
   - [ ] Read the example scenario: "You're debugging a Terraform module, then check Azure docs, then discuss deployment strategy. Copilot starts suggesting Bicep when you're working in Terraform."
   - **Validation checkpoint**: Which signal from the table does this match?
   - [ ] Identify 2-3 other potential drift scenarios from your own experience
   - [ ] **Expected result**: Confidence recognizing drift patterns in real-time

3. **Understand** early detection benefits
   - [ ] Recognize that early detection prevents compounding confusion
   - [ ] Learn that restoring earlier saves more time than continuing with drift
   - **Pro tip**: Set a mental checkpoint after each major task completion—makes restoration easier
   - [ ] **Expected result**: Proactive mindset for context monitoring

### Task 2: Use Restore Checkpoint Feature (10 minutes)

<!-- AI_COACH: Guide learner to discover the restore checkpoint button through exploration before revealing exact location. Ask: "Where in the Copilot Chat interface would you expect to find conversation history controls? What icons might represent 'going back' in a conversation?" -->

**What You'll Do**: Locate and use the restore checkpoint feature to recover conversation state.

**Steps**:

1. **Locate** the restore checkpoint button
   - [ ] Open GitHub Copilot Chat panel in VS Code
   - [ ] Look for the conversation history controls (typically top-right of chat panel)
   - [ ] Find the restore/rewind icon near the conversation history dropdown
   - **Pro tip**: The icon typically looks like a circular arrow or clock symbol
   - [ ] **Expected result**: Located the restore checkpoint button in your interface

   **Visual Reference - Restore Checkpoint Button Location**:

   ```text
   ┌─────────────────────────────────────────────┐
   │  GitHub Copilot Chat              🔄 ⋮ ✕   │ ← Restore button (🔄)
   ├─────────────────────────────────────────────┤
   │  Your conversation messages here...         │
   │                                             │
   └─────────────────────────────────────────────┘
   ```

   **Alt Text for Visual**: GitHub Copilot Chat interface showing the restore checkpoint button (circular arrow icon) in the top-right corner of the chat panel, next to the menu and close buttons.

2. **Practice** restoring to a previous state
   - [ ] Create a short conversation (3-4 exchanges) on any coding topic
   - [ ] Note a key piece of information the AI provided
   - [ ] Add 2-3 more messages that shift context
   - [ ] Click the restore checkpoint button
   - [ ] Select a checkpoint from before the context shift
   - [ ] Verify the AI still remembers the earlier context
   - **Validation checkpoint**: Ask the AI to recall something from before the shift—does it remember?
   - [ ] **Expected result**: Successfully restored to earlier conversation state with context intact

   <!-- AI_COACH: If learner struggles with recovery verification, prompt: "How could you test whether the AI still remembers specific details from before the drift occurred? Try asking it to reference earlier code or decisions." -->

3. **Understand** what gets preserved versus cleared
   - [ ] Recognize that checkpoints preserve conversation history up to the selected point
   - [ ] Understand that messages after the checkpoint are removed
   - [ ] Note that file context and workspace awareness are maintained
   - **Pro tip**: Checkpoint restore is different from undo—it removes future messages but keeps the selected message and all before it
   - [ ] **Expected result**: Clear mental model of checkpoint restoration behavior

### Task 3: Strategic Checkpoint Timing (5 minutes)

<!-- AI_COACH: Present scenarios and ask learner to choose restore vs. clear before showing the decision tree. Build judgment before rules. Ask: "Given what you've learned, when would restore help versus when would starting fresh make more sense?" -->

**What You'll Do**: Develop strategic judgment for when to restore checkpoints versus other options.

**Steps**:

1. **Review** the decision tree for restore versus clear
   - [ ] Study the decision flowchart below
   - [ ] Understand the decision factors: drift signals, token limits, task boundaries
   - **Validation checkpoint**: Can you explain why task boundaries matter for this decision?
   - [ ] **Expected result**: Clear decision framework for checkpoint management

   **Decision Flowchart - When to Restore vs. Clear**:

   ```mermaid
   flowchart TD
       A[Context Issue Detected] --> B{Near Token Limit?}
       B -->|Yes| C[Clear Conversation]
       B -->|No| D{Task Boundary?}
       D -->|At Boundary| C
       D -->|Mid-Task| E{Context Drift Only?}
       E -->|Yes| F[Restore Checkpoint]
       E -->|No - Multiple Issues| C
       F --> G[Resume Work]
       C --> H[Start Fresh]
   ```

   **Alt Text for Flowchart**: Decision flowchart showing when to use restore checkpoint versus clear conversation. Main decision points are token limit warnings, task boundaries, and whether drift is the only issue.

2. **Practice** checkpoint timing patterns
   - [ ] Identify good checkpoint moments: after completing a function, after deployment, after test pass
   - [ ] Recognize when to restore: mid-task drift, reference confusion, suggestion misalignment
   - [ ] Understand when to clear instead: token warnings, task completion, major topic change
   - **Pro tip**: Think of checkpoints like Git commits—create them at logical completion points
   - [ ] **Expected result**: Intuitive sense of checkpoint timing

   <!-- AI_COACH: Challenge learner with edge cases: "What if you're mid-task AND see token limit warnings? Which takes precedence—restoring to save context or clearing to manage token limits? Why?" -->

3. **Build** personal recovery workflows
   - [ ] Create a mental checklist: "Before major context switch → note current checkpoint"
   - [ ] Develop a habit: "See drift signal → check if mid-task → restore if yes"
   - [ ] Plan recovery strategy: "Know where your last good checkpoint was"
   - **Success criteria**: Can quickly decide restore vs. clear in real development scenarios
   - [ ] **Expected result**: Confident, automatic checkpoint management

## Completion Check

**You've Succeeded When**:

- [ ] You can identify 3+ context drift signals without reference
- [ ] You successfully restore conversation checkpoint and verify context recovery
- [ ] You can explain the difference between restore checkpoint and clear conversation
- [ ] You apply strategic checkpoint timing to maintain workflow efficiency

**Next Steps**: Continue to [Conversation Clearing Strategy](100-conversation-clearing-strategy.md) to learn when to clear conversations versus restore checkpoints.

---

## Reference Appendix

### Help Resources

- **GitHub Copilot Chat**: Use for conversation management and context recovery
- **VS Code**: Primary interface for checkpoint controls
- **Learning Kata Coach**: Interactive coaching for checkpoint strategy questions

### Professional Tips

- Set mental checkpoints after each task completion—makes restoration easier
- Early drift detection prevents compounding confusion and saves time
- Restore checkpoint is for mid-task recovery; clear conversation is for task boundaries
- Think of checkpoints like Git commits—mark logical completion points

### Troubleshooting

**Issue**: Can't find the restore checkpoint button

- **Quick Fix**: Check that you're using the latest GitHub Copilot extension. The button is typically in the top-right of the chat panel near conversation history controls.

**Issue**: Restored checkpoint but AI still seems confused

- **Quick Fix**: You may need to clear conversation entirely if drift was severe. Restore works best for single-topic drift, not multiple compounded issues.

**Issue**: Not sure which checkpoint to restore to

- **Quick Fix**: Look for the last message before the drift began. If unsure, restore to the last completed task or major decision point.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
