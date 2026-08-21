# Roles and authority

One person or agent can perform more than one role, but the authority and evidence for each role remain distinct. A reviewer must not approve its own unreviewed risk decision.

| Role | Owns | Must not do by inference |
| --- | --- | --- |
| Owner | Scope, priorities, exceptions, and remote authorization | Assume an agent has understood an unstated preference |
| Planner | Constraints, plan, risks, acceptance criteria, and validation design | Change product code while assigned plan-only work |
| Implementer | A scoped branch, batches, local commits, and evidence | Push, open a PR, merge, release, deploy, or delete without authorization |
| Reviewer | Independent assessment of correctness, regressions, and missing evidence | Treat unrun checks as passing or approve its own exception |
| Release operator | The authorized release or deployment procedure and operator evidence | Treat a successful push as a release or deployment |

## Modes and authorization

[Agent modes](/dev/agent-workflows/modes) defines the permitted local actions and required outcome for Plan, Inspect, Diagnose, Review, Implement, Verify, Deliver, and Monitor. The owner remains the only source of approval for remote or privileged actions.

Words such as “finish”, “urgent”, or “use Yeet” do not waive the authorization boundary. If a request says “use Yeet and push/open a PR”, those two remote actions are authorized; merge, release, and deployment still are not.

## Reporting contract

At each meaningful handoff, report:

- the selected flow and completed batch number;
- changed areas and the local commit created for the batch;
- commands run and their result;
- unrun or blocked checks, including why;
- remote actions completed only when they actually succeeded.

Never include credentials, private endpoints, access tokens, or machine-specific paths in a public report or commit.
