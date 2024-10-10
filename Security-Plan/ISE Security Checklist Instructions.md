# ISE Security Checklist Instructions

The ISE Security Checklist lives at the top of the Security Plan template and is a recommended set of security-focused tasks to complete throughout your engagement to deliver better security outcomes and posture.

Below you will find more detailed guidance on how to work through the ISE Security Checklist for your engagement. Make sure to track your progress via the [ISE SecDev Calculator](https://aka.ms/IseSecDevCalc) as you go along.

## Triage Security Recommendations/Findings - Defender for Cloud

```Regularly review your security recommendations using Defender for Cloud throughout your engagement. Create backlog items to remediate them as appropriate.```

Over the course of their engagements, dev crews should be actively reviewing Defender. The purpose of these reviews is to ensure that the work in the security plan is properly executed and what actually makes it to production is correctly configured following security best practices. At a minimum, we recommend reviewing your Defender score and recommendations at least three times over the course of the engagement (initial kickoff, work in progress review, final review). 

The secure score and recommendations for your subscription can be found by checking [Microsoft Defender for Cloud in the Azure Portal](https://portal.azure.com/#view/Microsoft_Azure_Security/SecureScoreDashboard).  

### Initial review
The initial review is the first time the team is reviewing the Defender findings and recommendations. Doing this review as early as possible is an opportunity for the dev crew to understand the security findings that are already present in the environment they are developing in. Having a baseline helps to communicate with the customer all the impact a team makes during an engagement.  

All reviews should be done in the environment that is or most closely reflects the ultimate production environment but are still meaningful if they must be done in a development environment. 

Over the course of the initial review meeting, the score is noted into the checklist tool and each recommendation is reviewed and backlog items are created for relevant work that is identified. At the end of the meeting, there should be a list of backlog items which are categorized into items that will be completed within the scope of the engagement and backlog items that will be left for the customer.


### Work in progress review
The work in progress review focuses on the list of new findings in Defender that have accumulated since the crew started to deploy their code. Note the current score in the the checklist tool. Did the score go up or down? Understanding why a score went up or down and communicating with all stakeholders in an important way to build trust. Add any new backlog items and categorize them appropriately. 

### Final review
The final review should occur before the final sprint of the engagement. Customer participation is recommended or at minimum the customer should be debriefed about the meeting. At this time, all work that is considered in scope should be complete and all work items that will be left for the customer should be reviewed and communicated with the customer. It's not best practice to address existing Defender recommendations in the last sprint as the final sprint should be left to deal with any emerging new work and revising the security plan so that it matches what is being delivered to the customer. 
In ISE we don’t defer security fundamentals.  There are no engagment types where it's appropriate to defer basic security fundamentals.   Sometimes there are recommendations that layer on multiple protections or enhance fundamentals that the customer will decide to put on the backlog. 

### FAQ

Q: I don’t have access to "Production" or the customer is deploying the code what should I do?
A: Reviewing the secure score and the recomendations in the environment where the code is developed is always an option. The focus of this work is to make sure that the code that we deliver does not introduce security risk and that the customer understands their security posture.  

Q: My customer does not use Defender or does not want to pay for Defender.
A: Defender recommendations are free.   Dev crews can review defender findings independently of their customer sharing the outcomes of their work in situations where it would not help the customer to learn from our "code with" practices.

Q: When is clicking not applicable (N/A) appropriate?
A: Very rarely!  In fact don’t be surprised if the security TD reaches out to you to learn about why it's not applicable. In cases where the dev crew is not delivering code to the customer this may be the best option.

Q: What if the customer uses another tool for recommendations? 
A: You should still review all Defender recommendations in your development environment for your resource group(s) and triage them appropriately. You can use the customers tool and review those findings as well.

Q: How should we handle Defender recommendations that try to upsell the customer? (e.g. "Microsoft Defender for X should be enabled")
A: When looking at those particular recommendations, evaluate the added protections to determine if the customer would truly benefit from enabling  extra coverage. If you recommend this extended functionality, be upfront with the customer about the extra costs they will incur.

Q: Are there any plans to develop a customer version of the checklist?
A: Our goal for now is not to build a customer-facing tool, but to help our development teams, security engineers, and security champions follow the best guidance to improve the security level of an engagement. It will help educate our customers on how to identify, what to identity and prioritize with respect to the  security issues for their backlog. Securedev will provide a 'process guidance' rather than tooling to support our crews with security during an engagement.

### Definition of done
Dev crews are given full points for completing each of the three required reviews. They get the credit by submitting the observed Defender score into the [Checklist tool](https://aka.ms/IseSecDevCalc).

## Customer Security Stakeholder Conversation

```Identify and meet with the customer’s security stakeholder during the start, middle, and end of the engagement. Identify and prioritize security requirements, share progress, and hand off unfinished backlog items.```

The objective here is to have an organic conversation with the customer's security stakeholder(s). Our focus primarily revolves around gathering their security goals and needs, followed by the prioritization of these requests.

Starting the conversation is as easy as asking:
- What security requirements should we be aware of as we plan and start this project?

It's highly likely the stakeholder will take the lead from here and this will be an exercise in active listening for you to develop a genuine understanding of their concerns and supporting requirements. Incorporating more specific questions may burden them unnecessarily.

However, in the rare instance where a security stakeholder may not have a predefined agenda, the sample questions below could be useful in elicting more details or requirements:

- What are your networking requirements?
- What are your identity requirements?
- Do you have a process for securely onboarding a new workload to Azure? 
- Are there regulatory, compliance, or governance requirements to be mindful of?
    - Is Azure Policy being used to enforce org-wide security standards?
- Do you have a standardized process for tracking and managing keys, secrets, and certificates?
- Is it acceptable to use Microsoft-managed keys for encryption, or does policy dictate Customer-managed keys (CMK) be used? 
- What does your source code security posture look like?
    - Do you require CICD scanning tools? (e.g., SAST/DAST/Credential/OSS)
    - What does your source code security review look like?

### Definition of done
Dev crews are given full points for having a productive and ongoing conversation with the customer’s security stakeholder throughout the engagement.

## ISE Security Champion

```Meet with an ISE security champion to review the design for your solution.```

Every engagement can benefit by having the help of either a security champion or a member of the Security TD. Depending on the crew's familiarity with the required security practices, the crew can decide exactly what this will look like. Some crews may want a member of the Security TD to work alongside the crew for some part of the engagement; other crews will ask a champion in their industry to review their plans. Engaging a champion or a Security TD member ensures the team is made aware of the latest practices, news, policies, etc., and can get all the benefits of a fresh set of eyes looking at the engagement plans. 

### Suggestions
- A champion can assist with the creation of a Security Plan (see the security plan section) 
- A champion can review the engagement's Security Plan  
- A champion can take on implementation of specific security related stories in the engagement 
- A champion can participate in the conversations with the customer about security 
- A champion can help the crew to complete the other ISE Security Checklist items 

### FAQ 
- How can I find a champion if I don't have one?
  - Check the [SolutionOps Champions dashboard](https://aka.ms/sochamps ) and adjust the filters to find a security champion in your industry.

### Definition of done
To complete the security champion section of the checklist, the crew must meet with a champion or Security TD member. During the meeting, the participants agree on the scope of work to be completed by the champion over the course of the engagement.   

## Security Plan

```With the help of a champion or the Security TD, review and identify the elements in this security plan template that will be completed during the engagement. Deliver the completed components to the customer so that they can integrate it into their threat model(s).```

Over the course of each engagement, dev crews should be augmenting the ISE GamePlan with an ISE Security Plan. An ISE Security Plan is based on the ISE Security Plan template. Each plan is customized to the engagement and has more or less information in it based on the needs of the engagement.  Crews are encouraged to work with Security Champions or a member of the Security TD to scope the template to the engagement and complete it.

### FAQ
- How can I learn more about Security Plans? 
  - See CSE Wiki, open a resource request, or ask in the Cybersecurity channel. 
- Do I have to complete every section of the template? 
  - At this time, it is up to dev crews to determine which parts of the template are relevant to the engagement. 
- Why don’t we call this a Threat Model? 
  - Because we don’t want to confuse our customers. An ISE Security Plan does not include any form of attestation or assertions that have been validated by a penetration test. 

### Definition of done
To complete the security plan section of the checklist, the team must complete all elements of the security plan that were included in scope. In addition, the security plan should be reviewed with the customer and checked in with the rest of the code that is delivered to the customer. 
