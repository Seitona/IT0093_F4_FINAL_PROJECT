# Part G test results (iPhone 17e simulator, iOS 27.1)

| # | Test | Result |
|---|------|--------|
| 1 | Add a subject; sorted by name | PASS |
| 2 | Empty subject name on Save | PASS (nothing added, no crash) |
| 3 | Task with empty title | PASS (alert "Title required") |
| 4 | Task with due date, High priority | PASS |
| 5 | Swipe right to mark done, then Undo | PASS |
| 6 | Edit a task title | PASS |
| 7 | Swipe left to delete a task | PASS |
| 8 | Note with text only | PASS (text icon in grid) |
| 9 | Note with a photo | PASS (grid and detail) |
| 10 | Delete note from detail with confirmation | PASS |
| 11 | Kill and relaunch; data persists | PASS |
| 12 | Delete subject; cascade removes tasks and notes | PASS |

Layout checked on iPhone 17e (smallest) and iPhone 18 Pro Max (largest): no clipping or overlap.
Not done: on-device run on a physical iPhone (Part H) and the Core Data Graph screenshot from Xcode's model editor.
