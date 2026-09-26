## verdict

1. Resolved: the mobile and desktop quiz completion captures show the completion heading without the decorative eyebrow. Source hides #quiz-position on completion and restores the actual question count in showRound. The no-JavaScript label now states the data-derived question total. The focused parent-run checks cover completion, replay, and restored progress; the regression assertions remain in scripts/check-date.sh.

No regressions from this fix were found. This ship verdict covers the scored fix, not a new review of the whole page.

## remaining

Clear.

disposition: ship
