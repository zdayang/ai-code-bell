#!/usr/bin/env python3
"""Gate Codex's native turn-ended notification on durable Goal state."""

from __future__ import annotations

import json
import os
import sqlite3
import sys
from pathlib import Path


INCOMPLETE_STATUSES = {
    "active",
    "paused",
    "blocked",
    "usage_limited",
    "budget_limited",
}


def goal_for_thread(thread_id: str) -> tuple[str, str] | None:
    db_path = Path(
        os.environ.get("CODEX_GOALS_DB", str(Path.home() / ".codex/goals_1.sqlite"))
    )
    with sqlite3.connect(f"file:{db_path}?mode=ro", uri=True, timeout=1) as db:
        row = db.execute(
            "SELECT goal_id, status FROM thread_goals WHERE thread_id = ?",
            (thread_id,),
        ).fetchone()
    return (str(row[0]), str(row[1])) if row else None


def should_forward(payload: dict[str, object]) -> bool:
    thread_id = str(
        payload.get("thread-id")
        or payload.get("thread_id")
        or payload.get("session_id")
        or ""
    )
    if not thread_id:
        return True

    goal = goal_for_thread(thread_id)
    if goal is None:
        return True

    goal_id, status = goal
    if status in INCOMPLETE_STATUSES:
        return False
    if status != "complete":
        return True

    marker_dir = Path(
        os.environ.get(
            "CODEX_NATIVE_NOTIFY_STATE_DIR",
            str(Path.home() / ".local/state/ai-notify/native-completed-goals"),
        )
    )
    marker_dir.mkdir(parents=True, exist_ok=True)
    marker = marker_dir / goal_id
    try:
        marker.touch(exist_ok=False)
    except FileExistsError:
        return False
    return True


def main() -> int:
    if len(sys.argv) < 4:
        return 2

    native_command = sys.argv[1]
    native_args = sys.argv[2:]
    try:
        payload = json.loads(native_args[-1])
        if isinstance(payload, dict) and not should_forward(payload):
            return 0
    except Exception:
        # Fail open so a Codex schema or local database change does not disable
        # all native notifications.
        pass

    os.execv(native_command, [native_command, *native_args])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
