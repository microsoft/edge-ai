---
title: 'Kata: 300 - Context Optimization and Token Management'
description: Learn advanced prompt engineering techniques for optimizing token usage, managing context windows, and handling conversation memory in production AI systems
author: microsoft/edge-ai
ms.date: 2025-01-20
kata_id: prompt-engineering-300-context-optimization
kata_category:
  - prompt-engineering
kata_difficulty: 3
estimated_time_minutes: 90
learning_objectives:
  - Accurately count tokens and understand how different content types consume context budgets
  - Apply optimization techniques to reduce token usage by 20%+ while maintaining effectiveness
  - Design and implement conversation memory strategies for multi-turn interactions within context constraints
  - Build prompts that gracefully handle context window limits and production deployment requirements
  - Apply enterprise prompt engineering techniques that scale from prototypes to production
prerequisite_katas:
  - prompt-engineering-02-basic-prompt-structure
  - ai-assisted-engineering-100-getting-started-basics
technologies:
  - GitHub Copilot
success_criteria:
  - Analyze prompts and accurately count tokens using appropriate tokenizers
  - Apply optimization techniques reducing token usage by at least 20% while preserving functionality
  - Implement conversation memory strategy maintaining context across multiple turns without overflow
  - Deploy optimized prompt handling context window limits gracefully with error handling
  - Create clear documentation with before/after metrics showing measurable improvements
ai_coaching_level: guided
scaffolding_level: medium
hint_strategy: progressive
common_pitfalls:
  - Over-optimizing and losing prompt clarity or effectiveness
  - Not testing optimizations with realistic conversation lengths
  - Implementing memory strategies without considering model-specific context limits
  - Ignoring token counting differences between models
requires_azure_subscription: false
requires_local_environment: true
tags:
  - prompt-engineering
search_keywords:
  - context-optimization
  - token-management
  - conversation-memory
  - context-window-limits
  - prompt-optimization
---

## Quick Context

**You'll Learn**: Advanced prompt engineering techniques for optimizing token usage, managing context windows, and handling conversation memory in production AI systems.

**Prerequisites**:

- Completion of prompt-engineering kata 01 (prompt creation workflow)
- Completion of prompt-engineering kata 02 (basic prompt structure)
- Access to a prompt file created in previous katas
- Understanding of how AI models use tokens and context windows

**Real-World Context**: Effective context management is crucial for AI-assisted development. This kata teaches advanced techniques for optimizing context windows, managing token limits, and structuring information for maximum AI comprehension and output quality.

## Essential Setup

**Complete these checks before starting** - verifying your setup ensures successful kata completion:

- [ ] **Completed Prerequisites**: Finished prompt-engineering kata 01 and 02
- [ ] **Prompt File Available**: Have your professional prompt from kata 02 ready for optimization
- [ ] **Tokenizer Access**: Can access a tokenizer for your target AI model (e.g., tiktoken for OpenT, Claude tokenizer)
- [ ] **AI Tool Access**: GitHub Copilot, Claude, or another AI coding assistant available
- [ ] **Documentation Template**: Have a place to document optimization strategies and measurements

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on 03 - Context Optimization and Token Management kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Context Window Analysis and Token Counting (12-15 minutes)

**What You'll Do**: Analyze your prompt's token usage, understand how different sections consume your context budget, and identify optimization opportunities.

**Steps**:

1. **Set up token counting for your prompt**
   - [ ] Ask your AI assistant: "How do I count tokens in this prompt file using the appropriate tokenizer?"
   - [ ] Install or access the tokenizer for your target model (tiktoken for OpenAI models, etc.)
   - [ ] Create a script or use a tool to count tokens in your prompt file
   - [ ] **Expected result**: Working token counter that gives accurate counts for your prompt

2. **Analyze token distribution across prompt sections**
   - [ ] Count tokens in each major section: frontmatter, instructions, examples, constraints
   - [ ] Ask: "Which sections of my prompt consume the most tokens and why?"
   - [ ] Create a breakdown showing token usage per section (e.g., "Instructions: 450 tokens, Examples: 280 tokens")
   - [ ] **Expected result**: Detailed token usage breakdown identifying high-consumption areas

3. **Identify optimization opportunities**
   - [ ] Ask your AI assistant: "What optimization techniques could reduce token usage in this prompt without losing effectiveness?"
   - [ ] Review each section and identify verbose language, redundant instructions, or optimization candidates
   - [ ] Create a prioritized list of optimization opportunities with estimated token savings
   - [ ] **Success check**: You have a specific optimization plan targeting sections with highest token savings potential

### Task 2: Apply Token Optimization Techniques (15-18 minutes)

**What You'll Do**: Implement optimization strategies to reduce your prompt's token usage by 20% or more while maintaining effectiveness.

**Steps**:

1. **Optimize instruction language**
   - [ ] Ask: "How can I make these instructions more concise without losing clarity?"
   - [ ] Replace verbose phrases with concise equivalents (e.g., "in order to" → "to")
   - [ ] Use imperative verbs consistently (e.g., "you should validate" → "validate")
   - [ ] Remove redundant words and phrases identified in Task 1
   - [ ] **Expected result**: Instructions section reduced by at least 15% tokens while maintaining clarity

2. **Consolidate and compress examples**
   - [ ] Review examples for redundancy: Do multiple examples demonstrate the same concept?
   - [ ] Ask: "Can I merge these examples or use more compact code samples?"
   - [ ] Keep essential examples but compress verbose ones
   - [ ] Consider using shorter variable names and removing comments in code examples if context is clear
   - [ ] **Expected result**: Examples section maintains coverage but uses 20%+ fewer tokens

3. **Optimize context sections**
   - [ ] Review background and context sections for essential vs. nice-to-have information
   - [ ] Ask: "What context is absolutely required vs. what can be referenced externally?"
   - [ ] Move non-critical reference information to external documentation links
   - [ ] Keep only context that directly impacts prompt execution
   - [ ] **Expected result**: Context sections streamlined to essential information only

4. **Measure optimization results**
   - [ ] Re-count tokens in your optimized prompt using your tokenizer
   - [ ] Calculate percentage reduction: ((original - optimized) / original) × 100
   - [ ] Verify functionality: Test the optimized prompt with sample inputs
   - [ ] **Success check**: Achieved 20%+ token reduction with maintained or improved prompt effectiveness

### Task 3: Implement Conversation Memory Management (10-15 minutes)

**What You'll Do**: Design and implement a conversation memory strategy that maintains context across multiple turns without hitting context window limits.

**Steps**:

1. **Design your memory strategy**
   - [ ] Ask: "What conversation memory strategy fits a [describe your use case] scenario?"
   - [ ] Choose an approach: sliding window (last N messages), summarization (compress old messages), or hybrid
   - [ ] Define memory boundaries: How many turns? When to reset? What to prioritize?
   - [ ] **Expected result**: Clear memory strategy documented with rationale for your use case

2. **Implement memory management logic**
   - [ ] Add instructions to your prompt for handling conversation history
   - [ ] Specify how to handle context window overflow: "When conversation exceeds X tokens, summarize messages older than Y turns"
   - [ ] Include examples of memory management in action (before/after summarization)
   - [ ] Add error handling: "If context limit reached, respond with: 'Conversation too long, starting new context'"
   - [ ] **Expected result**: Prompt includes clear memory management instructions with examples

3. **Test memory strategy**
   - [ ] Simulate a multi-turn conversation with your AI assistant
   - [ ] Ask: "Let's test this prompt with a 10-turn conversation about [topic]. Does memory management work correctly?"
   - [ ] Verify the prompt maintains relevant context while respecting token limits
   - [ ] Test edge cases: What happens at context boundaries? Does summarization preserve key information?
   - [ ] **Success check**: Conversation memory works across multiple turns without overflow, maintaining relevant context

4. **Document production considerations**
   - [ ] Add comments to your prompt documenting: token budget, memory strategy, overflow handling
   - [ ] Create a "Production Deployment" section in your prompt documentation
   - [ ] Document monitoring recommendations: "Track conversation length, monitor token usage per turn"
   - [ ] **Expected result**: Production-ready prompt with clear deployment and monitoring guidance

## Completion Check

You have successfully completed this kata when:

- ✅ **Token Analysis Complete**: You can accurately count tokens in prompts and understand token distribution across sections
- ✅ **Optimization Achieved**: Your prompt uses 20%+ fewer tokens than the original while maintaining or improving effectiveness
- ✅ **Memory Management Working**: Conversation memory strategy handles multi-turn interactions within context window limits
- ✅ **Production Ready**: Your optimized prompt includes error handling, monitoring guidance, and deployment documentation
- ✅ **Measurable Results**: You have before/after metrics showing token reduction and verified functionality

**Validation questions**:

1. Can you explain how different sections of your prompt consume tokens and why?
2. What specific optimization techniques did you apply and what were the measurable results?
3. How does your conversation memory strategy prevent context window overflow?
4. What happens when your prompt reaches token limits in production?

---

## Reference Appendix

### Help Resources

- [OpenAI Tokenizer (tiktoken)](https://github.com/openai/tiktoken) - Token counting for OpenAI models
- [Anthropic Claude Tokenization](https://docs.anthropic.com/claude/docs/models-overview) - Understanding Claude's tokenization
- [Prompt Engineering Guide](https://www.promptingguide.ai/) - Token optimization best practices
- [OpenAI Prompt Engineering](https://platform.openai.com/docs/guides/prompt-engineering) - Context window management patterns
- Repository prompts: `.github/prompts/` - Real-world optimization examples

### Professional Tips

- Measure token usage before optimizing to establish baseline and track improvements
- Target 20-30% token reduction without sacrificing prompt clarity or effectiveness
- Use concise language and imperative verbs to reduce verbose instructions
- Consolidate redundant examples while maintaining coverage of key patterns
- Implement memory strategies proactively before hitting context limits in production

### Troubleshooting

**Token optimization breaks prompt effectiveness**:

- Revert changes and optimize incrementally, testing effectiveness after each change
- Identify which sections are critical for quality and maintain their token budget
- Focus optimization on examples and context rather than core directives

**Context window limits reached unexpectedly**:

- Implement conversation summarization for messages older than N turns
- Add explicit memory management instructions with token thresholds
- Test with realistic multi-turn conversations to validate memory strategy

**Token counts vary between models**:

- Use model-specific tokenizers (tiktoken for OpenAI, Claude tokenizer for Anthropic)
- Document which tokenizer was used for measurements to ensure consistency
- Test optimized prompts with target model to verify actual token consumption

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
