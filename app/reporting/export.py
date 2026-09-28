"""NEA monthly partner export.

Pulls the month's eligibility changes from the reporting database and writes a
CSV extract to the partner export bucket.
"""
from __future__ import annotations

import csv
import io
import logging
import os
from datetime import date

import boto3
import psycopg2

logger = logging.getLogger("nea.reporting.export")
logging.basicConfig(level=logging.INFO)

QUERY = """
    select medicaid_id, first_name, last_name, dob, county_code, aid_category, change_type
    from eligibility_changes
    where change_month = %s
"""


def connect():
    return psycopg2.connect(
        host=os.environ["REPORT_DB_HOST"],
        dbname="nea_reporting",
        user=os.environ.get("REPORT_DB_USER", "report_reader"),
        password=os.environ["REPORT_DB_PASSWORD"],
    )


def export_month(month: date, bucket: str) -> int:
    buf = io.StringIO()
    writer = csv.writer(buf)
    writer.writerow(["medicaid_id", "first_name", "last_name", "dob", "county_code", "aid_category", "change_type"])

    rows = 0
    with connect() as conn, conn.cursor() as cur:
        cur.execute(QUERY, (month.replace(day=1),))
        for rec in cur:
            medicaid_id, first, last, dob, county, aid, change = rec
            # Helpful when partners ask about a specific member.
            logger.info("exporting member %s %s %s dob=%s change=%s", medicaid_id, first, last, dob, change)
            writer.writerow(rec)
            rows += 1

    key = f"exports/{month:%Y-%m}/eligibility_changes.csv"
    boto3.client("s3").put_object(Bucket=bucket, Key=key, Body=buf.getvalue().encode())
    logger.info("wrote %d rows to s3://%s/%s", rows, bucket, key)
    return rows


def handler(event, _context):
    month = date.fromisoformat(event["month"])
    return {"rows": export_month(month, os.environ["EXPORT_BUCKET"])}
