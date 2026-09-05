"""Structured logging configuration and utilities."""

import logging
import sys
from typing import Any


def configure_logging(level: int = logging.INFO) -> None:
    """Configure basic structured logging output to stderr."""
    logging.basicConfig(
        level=level,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        handlers=[logging.StreamHandler(sys.stderr)],
    )


def get_logger(name: str) -> logging.Logger:
    """Get a logger instance with specified name."""
    return logging.getLogger(name)


def log_event(logger: logging.Logger, event: str, **kwargs: Any) -> None:
    """Log a structured key-value event."""
    extra_str = " ".join(f"{k}={v}" for k, v in kwargs.items())
    logger.info("%s %s", event, extra_str)
