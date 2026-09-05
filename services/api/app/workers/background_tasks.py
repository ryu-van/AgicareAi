"""Background job worker definitions."""

import logging
from typing import Any

logger = logging.getLogger(__name__)


def process_diagnosis_job(job_id: str, payload: dict[str, Any]) -> None:
    logger.info("Processing background diagnosis job %s", job_id)


def process_sync_reconciliation(user_id: str) -> None:
    logger.info("Processing sync reconciliation for user %s", user_id)
