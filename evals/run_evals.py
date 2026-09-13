"""
Runs all 10 scenarios and prints a pass/fail scorecard.

Usage: python3 -m evals.run_evals
"""
import time
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from evals.scenarios import ALL_SCENARIOS


def main():
    print("=" * 64)
    print("VERITY EVAL SUITE — 10 scenarios, mocked HTTP (see scenarios.py docstring)")
    print("=" * 64)

    passed = 0
    failed = 0
    rows = []

    for name, fn in ALL_SCENARIOS:
        start = time.time()
        try:
            ok, note = fn()
            elapsed_ms = (time.time() - start) * 1000
            if ok:
                passed += 1
                rows.append((name, "PASS", note, elapsed_ms))
            else:
                failed += 1
                rows.append((name, "FAIL", note, elapsed_ms))
        except AssertionError as e:
            failed += 1
            rows.append((name, "FAIL", str(e), (time.time() - start) * 1000))
        except Exception as e:
            failed += 1
            rows.append((name, "ERROR", f"{type(e).__name__}: {e}", (time.time() - start) * 1000))

    print()
    for name, status, note, ms in rows:
        mark = "[PASS]" if status == "PASS" else "[FAIL]" if status == "FAIL" else "[ERR ]"
        print(f"{mark} {name} ({ms:.1f}ms)")
        print(f"       {note}")

    print()
    print("=" * 64)
    print(f"RESULT: {passed}/{len(ALL_SCENARIOS)} passed")
    print("=" * 64)

    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
