import importlib.util
from pathlib import Path
import unittest


SCRIPT = Path(__file__).with_name("gh_pr_ops.py")
spec = importlib.util.spec_from_file_location("gh_pr_ops", SCRIPT)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class TestGhPrOps(unittest.TestCase):
    def test_is_new_item_true(self):
        item = {
            "kind": "issue_comment",
            "body": "please fix this",
            "reactions": {"hooray": 0},
        }
        self.assertTrue(mod.is_new_item(item, "hooray", "🤖"))

    def test_is_new_item_false_when_marked(self):
        item = {
            "kind": "issue_comment",
            "body": "already handled",
            "reactions": {"hooray": 1},
        }
        self.assertFalse(mod.is_new_item(item, "hooray", "🤖"))

    def test_is_new_item_false_when_bot_prefixed(self):
        item = {
            "kind": "issue_comment",
            "body": "🤖 Addressed in abc123",
            "reactions": {},
        }
        self.assertFalse(mod.is_new_item(item, "hooray", "🤖"))

    def test_is_new_item_false_for_review_reply(self):
        item = {
            "kind": "review_comment_reply",
            "body": "please see above",
            "reactions": {},
        }
        self.assertFalse(mod.is_new_item(item, "hooray", "🤖"))


if __name__ == "__main__":
    unittest.main()
