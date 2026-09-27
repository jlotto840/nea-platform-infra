"""NorthStar Eligibility Analytics (NEA) - member eligibility ingest.

Fictitious sample code for the OHIP Standards Agentic POC. Reads eligibility
records from the raw zone, validates them, and writes curated records.
Quality-gate failures go to the quarantine list with a rejection reason; nothing
is dropped silently. Logs never contain unmasked PHI/PII.
"""
from __future__ import annotations

import hashlib
import logging
import re
from dataclasses import dataclass, field
from datetime import date, datetime, timezone

logger = logging.getLogger("nea.ingest")

MEDICAID_ID = re.compile(r"^[A-Z]{2}\d{5}[A-Z]$")


def mask_id(value: str) -> str:
    """Stable, non-reversible token for correlating log lines without exposing the ID."""
    if not value:
        return "<empty>"
    return "id#" + hashlib.sha256(value.encode()).hexdigest()[:10]


@dataclass
class Member:
    medicaid_id: str
    first_name: str
    last_name: str
    dob: date
    county_code: str
    aid_category: str


@dataclass
class BatchResult:
    run_id: str
    accepted: list[Member] = field(default_factory=list)
    quarantined: list[dict] = field(default_factory=list)

    @property
    def record_count(self) -> int:
        return len(self.accepted) + len(self.quarantined)


def validate(member: Member, as_of: date) -> str | None:
    """Return a rejection reason code, or None if the record passes the quality gate."""
    if not MEDICAID_ID.match(member.medicaid_id or ""):
        return "QG01_INVALID_MEDICAID_ID"
    if member.dob > as_of:
        return "QG02_DOB_IN_FUTURE"
    if not member.county_code or len(member.county_code) != 2:
        return "QG03_INVALID_COUNTY"
    if not member.aid_category:
        return "QG04_MISSING_AID_CATEGORY"
    return None


def run_batch(run_id: str, members: list[Member], as_of: date | None = None) -> BatchResult:
    as_of = as_of or date.today()
    result = BatchResult(run_id=run_id)
    started = datetime.now(timezone.utc)
    logger.info("run=%s start records=%d", run_id, len(members))

    for m in members:
        reason = validate(m, as_of)
        if reason:
            result.quarantined.append({
                "member": mask_id(m.medicaid_id),
                "rejection_reason": reason,
                "rejection_timestamp": datetime.now(timezone.utc).isoformat(),
                "pipeline_run_id": run_id,
            })
            # Masked token only - never the raw ID, name or date of birth.
            logger.warning("run=%s quarantined member=%s reason=%s", run_id, mask_id(m.medicaid_id), reason)
        else:
            result.accepted.append(m)

    logger.info(
        "run=%s end accepted=%d quarantined=%d seconds=%.1f",
        run_id, len(result.accepted), len(result.quarantined),
        (datetime.now(timezone.utc) - started).total_seconds(),
    )
    return result
