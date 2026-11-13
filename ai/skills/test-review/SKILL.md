---
name: test-review
description: Review the tests in a change set for impact. Flags low-value tests to cut and high-risk behavior left untested. Use for test suite review, or as the testing part of a code review.
argument-hint: "[PR, branch, or commit range. Defaults to local changes against main]"
---

Review the tests added or changed in a change set. Judge each test by the problem it would catch. Code coverage is not an explicit goal; prefer a lean but effective test suite.

## Weigh each test by the cost of the failure it prevents

**High cost.** Correctness of core functionality, data corruption or loss, security (auth, permissions, input handling), embedded and real-time behavior, and anything hard to detect or recover from once shipped. A higher volume of tests is fine here, especially when they are cheap to write, maintain, and run, as long as each one checks distinct behavior that matters.

**Low cost.** Internal CLI tools, dev scripts, and anything only developers run on their laptops and could fix in minutes if it broke. Keep only tests that prevent real damage, such as a script that deletes or migrates data. Recommend cutting or reducing the rest.

## Flag for cutting, merging or rewriting

- Tests that re-implement the code: expected values computed with the same logic as the implementation, or assertions that mocks were called the way the code happens to call them.
- Tests of trivial behavior: getters, constants, argument parsing, pass-through wrappers, behavior of the framework or a library.
- Redundant tests: several cases through the same path with inputs that do not differ in a way that matters. Merge into one parametrized test or cut.
- Tests tied to internals that would fail on a refactor with no change in behavior.
- Tests whose setup is much larger than the risk they cover.

## Flag gaps

Name high-cost behavior in the change that has no test, or only a happy-path test: error handling, boundary values, concurrency, failure and recovery paths. Skip gaps in low-cost code.

## Output

Give a succinct list, ordered by importance and grouped by recommendation (cut/merge vs improve/add), with your findings. Report only. Edit tests after approval or discourse unless told otherwise.
