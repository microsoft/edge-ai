
# Learning Kata Coach

Welcome to the **Learning Kata Coach** – your personalized AI mentor for focused practice exercises and skill development!

## 🚀 Get Started

description: 'Learning coach chatmode for interactive AI-powered skill assessment and learning path recommendations'

The Learning Kata Coach is available as a GitHub Copilot Chat mode in VS Code. Here's how to access it:

### Option 1: VS Code GitHub Copilot Chat

1. **Open VS Code** in your edge-ai workspace
1. **Open GitHub Copilot Chat** (Ctrl+Shift+I or Cmd+Shift+I)
1. **Type the chat mode command**:

  ```text
  @workspace #file:.github/chatmodes/learning-kata-coach.chatmode.md
  ```

1. **Start your conversation** with your learning goals!

### Option 2: Direct File Reference

If you have GitHub Copilot installed, you can also reference the chatmode directly:

**Chat Mode File**: [`.github/chatmodes/learning-kata-coach.chatmode.md`](../../.github/chatmodes/learning-kata-coach.chatmode.md)

## 🎯 What the Kata Coach Can Help With

- **Personalized Learning Paths**: Based on your skill assessment results
- **Focused Practice Exercises**: Hands-on coding challenges (katas)
- **Progress Tracking**: Monitor your learning journey
- **Skill Development**: From foundation to expert level
- **Real-world Applications**: Edge AI and cloud development scenarios

## 💡 Getting the Most from Your Coaching Session

1. **Share Your Assessment Results**: Tell the coach your skill level from the assessment
2. **Be Specific**: Mention specific technologies or areas you want to focus on
3. **Ask for Practice**: Request specific katas or exercises
4. **Track Progress**: Use the coach to update your learning dashboard

## 🤖 Example Conversation Starters

- "I just completed the skill assessment and scored as a 'Skill Developer'. Can you create a personalized learning path for me?"
- "I want to practice Azure IoT Edge deployment. What katas do you recommend?"
- "Help me understand Kubernetes networking with hands-on exercises"
- "I'm struggling with Terraform modules. Can you give me a focused practice session?"

## 🔄 Integration with Learning Dashboard

Your kata coach sessions automatically integrate with your learning progress dashboard:

- **Progress Updates**: Completed katas are tracked
- **Skill Advancement**: Your skill level updates based on performance
- **Recommendations**: Get new kata suggestions based on your progress

## 📝 API Integration

### Learning Path Persistence

The Learning Kata Coach integrates with the backend API for saving and retrieving learning paths. The modal dialog calls the following endpoint:

#### POST /api/learning-paths/save

Saves assessment results and learning path recommendations.

**Request Schema:**

```json
  "type": "object",

  "properties": {
    "userId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_-]+$",
      "default": "default-user"
    },
    "pathType": {
      "type": "string",
      "enum": ["assessment-recommended", "custom", "guided"],
      "default": "assessment-recommended"
    },
    "assessmentResults": {
      "type": "object",
      "required": ["skillLevel", "score", "responses"],
      "properties": {
        "skillLevel": {
          "type": "string",
          "enum": ["Foundation Builder", "Skill Developer", "Expert Practitioner"]
        },
        "score": {
          "type": "number",
          "minimum": 0,
          "maximum": 100
        },
        "totalQuestions": {
          "type": "number",
          "minimum": 1
        },
        "responses": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["category", "score", "total"],
            "properties": {
              "category": { "type": "string" },
              "score": { "type": "number", "minimum": 0 },
              "total": { "type": "number", "minimum": 1 }
            }
          }
        }
      }
    },
    "recommendations": {
      "type": "object",
      "properties": {
        "chatmodeRecommendation": { "type": "string" },
        "learningPath": { "type": "string" }
      }
    },
    "timestamp": { "type": "string" },
    "metadata": {
      "type": "object",
      "properties": {
        "assessmentVersion": { "type": "string" },
        "sourceUrl": { "type": "string" },
        "sessionId": { "type": "string" }
      }
    }
  },
  "required": ["assessmentResults"]
}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "id": "unique-learning-path-id",
    "pathType": "assessment-recommended",
    "savedAt": "2025-09-21T16:43:10.000Z",
    "filepath": "path/to/saved/file.json"
  }
}
```

**Error Response:**

```json
{
  "success": false,
  "error": "Invalid request data",
  "validationErrors": [
    {
      "field": "assessmentResults.skillLevel",
      "message": "must be one of Foundation Builder, Skill Developer, Expert Practitioner"
    }
  ]
}
```

#### Additional Endpoints

- **GET /api/learning-paths/:userId** - Retrieve all learning paths for a user
- **GET /api/learning-paths/:userId/latest** - Get the most recent learning path
- **PATCH /api/learning-paths/:id/progress** - Update progress on a learning path

## 📚 Related Resources

- [Learning Dashboard](../learning/)
- [Skill Assessment](../learning/skill-assessment.html)
- [All Chat Modes](../.github/chatmodes/README.md)
- [Learning Paths](../learning/paths/)

---

**Ready to start learning?** Open GitHub Copilot Chat in VS Code and begin your personalized coaching session!
