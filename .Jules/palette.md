## 2026-06-26 - Adding ARIA labels to icon buttons
**Learning:** Icon buttons used throughout the application without accompanying text needed explicit ARIA labels to ensure screen reader accessibility. I noticed this pattern was present across various chat and contract components.
**Action:** Ensure all button components with size icon include an aria-label attribute if they only contain an icon.
