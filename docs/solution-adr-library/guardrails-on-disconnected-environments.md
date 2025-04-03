# AI Guardrails Implementation in a Disconnected Environment

Date: 2025-03-17

Authors: Omer Demir

## Status

- [ ] Draft
- [X] Proposed
- [ ] Accepted
- [ ] Deprecated

## Context

Acronyms used in the ADR have to be defined in the context section.

- **FPR:** False Positive Rate
- **FNR:** False Negative Rate
- **P50:** 50th Percentile
- **P99:** 99th Percentile

In high-security environments, internet access is restricted, making it impossible to use cloud-based moderation services such as Azure AI Safety.

To ensure safe and compliant AI operations in these disconnected (air-gapped) environments, we need a fully local guardrails solution that can filter
inappropriate content without external dependencies.

Key challenges include:

- Model Availability: Selecting a model that can operate locally with acceptable accuracy and latency.
- Dataset Selection: Choosing appropriate datasets to evaluate and benchmark the model without external API access.
- Performance Optimization: Ensuring the model runs efficiently on available hardware, which may have limited GPU/CPU resources.
- Security & Compliance: Avoiding proprietary cloud services that require internet access while maintaining high moderation standards.

## Decision

The following decisions have been made to enable guardrails on a disconnected environment:

- Use a locally deployed model for content moderation. Based on our evaluation, Llama-Guard-3-1B is selected due to its low False Positive Rate (FPR), acceptable False Negative Rate (FNR), and low latency compared to other models.
- Dataset Selection: The evaluation pipeline will primarily use ai-safety-institute/AgentHarm for content safety assessments and a golden dataset for false negative detection.
- Performance Considerations: The model should be optimized for low latency and reduced memory consumption using quantization or GPU acceleration where available.
- Security Compliance: The solution must ensure that no data is sent outside the local environment, meeting privacy and security requirements.

### Inappropriate categories

The following are a selection of categories identified by the MLCommons AI Safety working group deemed Hazard Categories. These categories were used in evaluating and benchmarking LLM models on how well they could respond to dangerous and/or inappropriate prompts. Refer to the AI Safety v0.5 POC for more details, [here](https://mlcommons.org/2024/04/mlc-aisafety-v0-5-poc/).

- **S1:** Violent Crimes
- **S2:** Non-Violent Crimes
- **S3:** Sex Crimes
- **S4:** Child Exploitation
- **S5:** Defamation
- **S6:** Specialized Advice
- **S7:** Privacy
- **S8:** Intellectual Property
- **S9:** Indiscriminate Weapons
- **S10:** Hate
- **S11:** Self-Harm
- **S12:** Sexual Content
- **S13:** Elections

## Decision Drivers

- Self-Sufficiency: The system must operate independently without cloud APIs.
- Performance Efficiency: The model should provide low latency and high accuracy within available computational limits.
- Security & Compliance: Ensuring that the solution meets air-gapped environment requirements while maintaining guardrails effectiveness.
- Scalability: Future-proofing the setup to allow easy integration of new datasets and models.

## Model Comparison

We evaluated multiple models based on False Positive Rate (FPR), False Negative Rate (FNR), Latency (P50, P99), and Setup Complexity:

| Model            | FPR   | FNR | Latency (P50/P99) | Setup Complexity | Notes                                                            |
|------------------|-------|-----|-------------------|------------------|------------------------------------------------------------------|
| Llama-Guard-3-1B | 0.61% | 19% | 0.02s / 0.04s     | Low              | Selected for its balance of accuracy, speed, and ease of setup.  |
| Llama-Guard-3-8B | 0.2%  | 38% | 0.07s / 0.11s     | High             | Higher accuracy but significantly higher FNR and slower latency. |

Based on this comparison, Llama-Guard-3-1B was chosen due to its low latency, reasonable FPR/FNR, and ease of deployment in an offline environment.

## Dataset Evaluation

We evaluated multiple datasets to determine which ones are best suited for testing content moderation in a disconnected environment.

| Dataset                                                                                                                         | Rows    | Categories                                                                                      | License             | Notes                                                      |
|---------------------------------------------------------------------------------------------------------------------------------|---------|-------------------------------------------------------------------------------------------------|---------------------|------------------------------------------------------------|
| [ai-safety-institute/AgentHarm](https://huggingface.co/datasets/ai-safety-institute/AgentHarm?library=datasets)                 | 416     | ['Disinformation', 'Harassment', 'Drugs', 'Fraud', 'Hate', 'Cybercrime', 'Sexual', 'Copyright'] | MIT                 | Selected for content safety evaluation.                    |
| [Deepset Prompt Injection](https://huggingface.co/datasets/deepset/prompt-injections)                                           | 662     | Prompt Injection                                                                                | Apache 2.0          | Not used in this phase (only relevant for security).       |
| [xTRam1/safe-guard-prompt-injection](https://huggingface.co/datasets/xTRam1/safe-guard-prompt-injection)                        | 10,296  | Prompt Injection                                                                                | Unknown             | Not selected due to lack of licensing information.         |
| [Babelscape/ALERT](https://huggingface.co/datasets/Babelscape/ALERT)                                                            | 44,000  | 6 macro / 32 micro categories                                                                   | CC BY-NC-SA 4.0     | Rejected due to restrictive license.                       |
| [Anthropic/hh-rlhf](https://huggingface.co/datasets/Anthropic/hh-rlhf)                                                          | Unknown | Human preference (helpfulness/harmlessness)                                                     | MIT                 | Rejected due to potential bias (used for LLM fine-tuning). |
| [Hate Speech and Offensive Language Dataset](https://www.kaggle.com/datasets/mrmorj/hate-speech-and-offensive-language-dataset) | 25,000  | Hate Speech, Offensive, Neutral                                                                 | CC0 (Public Domain) | Not used due to domain mismatch (Twitter-based).           |

[Azure AI Safety Adversarial Simulator](https://learn.microsoft.com/azure/ai-studio/how-to/develop/simulator-interaction-data#supported-adversarial-simulation-scenarios) is included in the table, however it is not dataset but rather a tool.

- Not a dataset but a tool to generate inappropriate content and test it
- Can manage both QA and conversation scenarios
- License: No license issues with the simulator

Final selection

- ai-safety-institute/AgentHarm for content safety evaluation.
- Golden dataset for false negative detection.

## Considered Options

### Option 1: Locally Deployed Llama-Guard-3-1B (Chosen)

- Pros:
  - Works offline with no external dependencies.
  - Good balance of FPR, FNR, and latency.
  - Can be further optimized via quantization.
- Cons:
  - May require additional hardware optimizations.
  - Lacks advanced cloud-based security checks.

### Other Option: Fine-tuned Phi-3.5-mini-instruct

_Even though it is highlighted here, It requires further exploration._

 Initial findings as follows;

- Pros:
  - Custom fine-tuning could improve performance for specific use cases.
- Cons:
  - High resource requirements, making it unsuitable for an offline setup.
  - Answer parsing is difficult.

### Other Option: Azure AI Safety

_Even though it is highlighted here, It requires further exploration._

 Initial findings as follows;

- Pros:
  - Comprehensive moderation capabilities.
- Cons:
  - Not viable in a disconnected environment since it requires internet access.

## Consequences

By adopting this decision:

- Self-Sufficiency: The solution operates independently, without cloud dependencies.
- Optimized Performance: The selected model balances latency and accuracy within local hardware constraints.
- Scalability: Future enhancements, such as fine-tuning and new datasets, can be added without disrupting the offline setup.
- Security & Compliance: The approach ensures full compliance with air-gapped environment policies.

## Future Considerations

- Hardware Optimization: Investigate quantization to reduce model size and optimize inference speed.
- Security Dataset Expansion: Evaluate prompt injection datasets to enhance guardrails against adversarial inputs.
- Multi-Language Support: Provide more dataset with different language support.
- Fine-tuning Exploration: Consider lightweight fine-tuning methods to improve accuracy without significantly increasing resource usage.
- Deployment Strategy Exploration: Consider packaged, k3s and other deployment strategies to deliver application.
