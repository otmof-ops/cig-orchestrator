"""Totals from a sales CSV, printed as one JSON object for the next task."""
import csv
import json
import sys
from collections import Counter


def summarize(rows):
    by_region = Counter()
    total = 0.0
    for row in rows:
        amount = float(row["amount"])
        total += amount
        by_region[row["region"]] += amount
    top = by_region.most_common(1)[0][0] if by_region else None
    return {"orders": len(rows), "total": round(total, 2), "top_region": top}


def main(path):
    with open(path, newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    print(json.dumps(summarize(rows)))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "sales.csv")
