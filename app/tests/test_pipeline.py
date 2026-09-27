import logging
from datetime import date

from app.ingest.pipeline import Member, mask_id, run_batch, validate

AS_OF = date(2026, 9, 1)


def member(**kw):
    base = dict(medicaid_id="AB12345C", first_name="Test", last_name="Person",
                dob=date(1980, 1, 1), county_code="31", aid_category="MA")
    base.update(kw)
    return Member(**base)


def test_valid_member_passes():
    assert validate(member(), AS_OF) is None


def test_invalid_id_rejected():
    assert validate(member(medicaid_id="123"), AS_OF) == "QG01_INVALID_MEDICAID_ID"


def test_future_dob_rejected():
    assert validate(member(dob=date(2030, 1, 1)), AS_OF) == "QG02_DOB_IN_FUTURE"


def test_bad_county_rejected():
    assert validate(member(county_code="3"), AS_OF) == "QG03_INVALID_COUNTY"


def test_missing_aid_category_rejected():
    assert validate(member(aid_category=""), AS_OF) == "QG04_MISSING_AID_CATEGORY"


def test_mask_is_stable_and_hides_id():
    assert mask_id("AB12345C") == mask_id("AB12345C")
    assert "AB12345C" not in mask_id("AB12345C")
    assert mask_id("") == "<empty>"


def test_batch_counts_and_quarantine_reason():
    res = run_batch("run-1", [member(), member(medicaid_id="bad")], AS_OF)
    assert res.record_count == 2
    assert len(res.accepted) == 1
    assert res.quarantined[0]["rejection_reason"] == "QG01_INVALID_MEDICAID_ID"
    assert res.quarantined[0]["pipeline_run_id"] == "run-1"


def test_logs_contain_no_phi(caplog):
    caplog.set_level(logging.INFO)
    run_batch("run-2", [member(medicaid_id="bad", first_name="Zelda", dob=date(2031, 5, 5))], AS_OF)
    text = caplog.text
    for phi in ("bad", "Zelda", "2031-05-05"):
        assert phi not in text
