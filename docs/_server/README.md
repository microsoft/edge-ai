# Kata Progress Server

This server enables persisting progress data to disk instead of downloading files.

## Quick Start

1. **Start the server:**

   ```bash
   cd server
   node progress-saver.js
   ```

2. **Server will run on:** <http://localhost:3001>

3. **Progress files saved to:** `docs/assets/data/progress/`

## API Endpoints

- `POST /api/progress/save` - Save progress data to disk
- `GET /api/progress/list` - List all saved progress files
- `GET /api/progress/load/{filename}` - Load specific progress file

## How It Works

1. When you export progress, it first tries to save to the server
2. If server is running → saves to `docs/assets/data/progress/kata-progress-{timestamp}.json`
3. If server is not running → falls back to browser download

## Integration

The Progress System Manager automatically detects if the server is running:

```javascript
// This now saves to disk instead of downloading
const data = await systemManager.exportProgressForCopilot();
```

## Production Setup

For production deployment, consider using:

- **PM2** for process management
- **nginx** for reverse proxy
- **Environment variables** for configuration
- **Authentication** for security

## Development

```bash
# Start server in development
npm run dev

# Or directly
node progress-saver.js
```
