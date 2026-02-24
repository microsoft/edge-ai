"""Static file serving for the web management UI."""

from __future__ import annotations

import logging
from pathlib import Path

from aiohttp import web

logger = logging.getLogger(__name__)


class WebUI:
    """Serves the single-page management UI and static assets."""

    def __init__(self, static_dir: str) -> None:
        self.static_dir = Path(static_dir)

    def setup_routes(self, app: web.Application) -> None:
        """Register static file routes on the application."""
        app.router.add_get("/", self.serve_index)
        app.router.add_get("/static/{path:.*}", self.serve_static)

    async def serve_index(self, _request: web.Request) -> web.Response:
        """Serve the main index.html page."""
        index_path = self.static_dir / "index.html"
        if not index_path.exists():
            return web.Response(text="UI not found", status=404)
        return web.FileResponse(index_path)

    async def serve_static(self, request: web.Request) -> web.Response:
        """Serve static files from the static directory."""
        rel_path = request.match_info["path"]
        file_path = self.static_dir / rel_path

        if not file_path.exists() or not file_path.is_file():
            return web.Response(text="Not found", status=404)

        # Prevent directory traversal
        try:
            file_path.resolve().relative_to(self.static_dir.resolve())
        except ValueError:
            return web.Response(text="Forbidden", status=403)

        return web.FileResponse(file_path)
