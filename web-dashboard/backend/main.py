"""
DEPRECATED: This module has been replaced by `main_fixed.py`.
It is preserved as a lightweight wrapper for backward compatibility only.

Please import and run `web-dashboard/backend/main_fixed.py` instead.
"""

import uvicorn

from .main_fixed import app  # re-export canonical app

if __name__ == "__main__":
    # Run the canonical application
    uvicorn.run(
        "web-dashboard.backend.main_fixed:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info",
    )
