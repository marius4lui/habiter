# Roles and authority

One person or agent can perform more than one role, but the authority and evidence for each role remain distinct. A reviewer must not approve its own unreviewed risk decision.

| Role | Owns | Must not do by inference |
| --- | --- | --- |
| Owner | Scope, priorities, exceptions, and remote authorization | Assume an agent has understood an unstated preference |
| Planner | Constraints, plan, risks, acceptance criteria, and validation design | Change product code while assigned plan-only work |
| Implementer | A scoped branch, batches, local commits, and evidence | Push, open a PR, merge, release, deploy, or delete without authorization |
| Reviewer | Independent assessment of correctness, regressions, and missing evidence | Treat unrun checks as passing or approve its own exception |
| Release operator | The authorized release or deployment procedure and operator evidence | Treat a successful push as a release or deployment |

## Task modes

| Request mode | Default permission |
| --- | --- |
| Plan, explain, inspect, review, or diagnose | Read-only. A plan document may be created only when requested. |
| Implement, fix, or change | Create a scoped branch, edit files, run local checks, and commit completed batches. |
| Push or open a pull request | Only when the owner explicitly requests that remote action. |
| Merge, release, deploy, delete, rotate credentials, or alter access | Only with separate, exact owner authorization. |

Words such as “finish”, “urgent”, or “use Yeet” do not waive the authorization boundary. If a request says “use Yeet and push/open a PR”, those two remote actions are authorized; merge, release, and deployment still are not.

## Reporting contract

At each meaningful handoff, report:

- the selected flow and completed batch number;
- changed areas and the local commit created for the batch;
- commands run and their result;
- unrun or blocked checks, including why;
- remote actions completed only when they actually succeeded.

Never include credentials, private endpoints, access tokens, or machine-specific paths in a public report or commit.
