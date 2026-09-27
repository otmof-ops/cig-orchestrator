import unittest

from stats import summarize


class SummarizeTest(unittest.TestCase):
    def test_totals(self):
        rows = [
            {"region": "north", "amount": "10.5"},
            {"region": "south", "amount": "4"},
            {"region": "north", "amount": "1"},
        ]
        self.assertEqual(summarize(rows), {"orders": 3, "total": 15.5, "top_region": "north"})

    def test_empty(self):
        self.assertEqual(summarize([]), {"orders": 0, "total": 0.0, "top_region": None})


if __name__ == "__main__":
    unittest.main()
