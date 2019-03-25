# General workflow

## Test Changes
0. Run `bin/promote prod' to update `test/` from current `prod/` (may be no changes)
1. Modify `/test` and update `prod/test-strongbox.yml` (protected file) if required.
1. Add commit(s) for changes
2. Test locally (`make validate`) or push to upstream PR for CI to chew.
4. Merge PR.

## Stage Changes
0. Redeploy current stage environment, update `prod/stage-strongbox.yml` (protected file) if required.
1. Run `bin/promote test`
1. Add commit for stage change
2. Test locally (``make stage_env``) or (TODO) push to upstream PR for CI to chew on it.
7. Merge PR

## Prod Changes
0. Redeploy current prod environment, update `prod/prod-strongbox.yml` (protected file) if required.
6. Run `bin/promote stage`
7. Add commit for prod change, tag with next appropriate version
8. Deploy locally or (TODO) push to upstream PR for CI to chew on it.

## TODOS:

* Need 'make validate' to support running against `test` and `prod` environments
* Need automation support for running tests against `stage` vs `test`
* Need automation support for CD deploy of prod + automated testing and reporting
