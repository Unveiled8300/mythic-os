# Git Workflow Standard

> **TL;DR:** Feature branches per story, conventional commits, squash-merge into epic branches,
> merge-commit into main. PRs under 400 lines. No direct pushes to main.

---

## Branch Naming

| Branch Type | Pattern | Example |
|------------|---------|---------|
| Epic | `epic/[N]-[slug]` | `epic/4-git-workflow` |
| Story | `story/[epic]-[story-slug]` | `story/e4-conventional-commits` |
| Bug fix | `fix/[T-ID]-[slug]` | `fix/T-12-login-redirect` |
| Hotfix | `hotfix/[slug]` | `hotfix/auth-token-expiry` |
| Chore | `chore/[slug]` | `chore/update-deps` |

**Rules:**
- Lowercase, hyphen-separated. No underscores, no camelCase.
- Branch from latest `main` (or parent epic branch for stories).
- Delete branch after merge — no stale branches.

---

## Conventional Commits

All commits follow the conventional commits specification.

### Format

```
type(scope): subject

[optional body]

[optional footer]
```

### Types

| Type | When |
|------|------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests |
| `chore` | Maintenance, dependency updates, tooling |
| `ci` | CI/CD pipeline changes |
| `style` | Formatting, whitespace (no logic change) |
| `perf` | Performance improvement |

### Scope

Optional but recommended. Use the task ID when applicable:

```
feat(T-01): add user registration endpoint
fix(T-03): correct email validation regex
docs(governance): update Storyteller SOP for hot/cold split
ci: add PR size check to GitHub Actions
```

### Subject Line Rules

- ≤ 72 characters
- Imperative mood ("add", not "added" or "adds")
- No period at end
- Lowercase first word after colon

### Body

- Separated from subject by blank line
- Wrap at 72 characters
- Explain **why**, not **what** (the diff shows what)

### Footer

- Reference task IDs: `Refs: T-01, T-02`
- Breaking changes: `BREAKING CHANGE: [description]`
- Co-authorship: `Co-Authored-By: [name] <email>`

---

## Governance Commits

Governance files (LIBRARY.md, CLAUDE.md, rules/, skills/, adr/, error-records/) use
the `/git-sync` skill format:

```
docs(governance): [Storyteller: ACTION] [resource_id] [description]
```

This is a specialized conventional commit — `docs` type, `governance` scope.
The `/git-sync` skill enforces this format automatically.

---

## Pull Request Standards

### Title

Matches conventional commit format: `type(scope): description`

### Body Template

```markdown
## Summary
- [bullet point 1]
- [bullet point 2]

## SPEC.md Criteria Covered
- [ ] [criterion from Section 6]

## Test Plan
- [ ] [test step 1]
- [ ] [test step 2]
```

### Size Limit

**Maximum 400 lines changed** (excluding lock files and generated code).

PRs exceeding 400 lines must be split into smaller PRs. CI enforces this gate
via the `pr-size` job in GitHub Actions.

Excluded from line count:
- `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
- `requirements.txt` (pip freeze output)
- `*.generated.*` files
- Prisma migration SQL (auto-generated)

### Review Requirements

| Track | Requirement |
|-------|------------|
| Quick | Self-merge after CI passes |
| Standard | 1 reviewer + CI passes |
| Enterprise | 1 reviewer + adversarial /peer-review + CI passes |

---

## Merge Strategy

| Merge Into | Strategy | Why |
|-----------|----------|-----|
| Epic branch ← Story branch | Squash and merge | Keeps epic history clean; one commit per story |
| Main ← Epic branch | Merge commit | Preserves epic boundary in main's history |
| Main ← Hotfix | Squash and merge | Single atomic fix |

After merge: delete the source branch.

---

## Protected Branches

| Branch | Rules |
|--------|-------|
| `main` | CI must pass + 1 approval (Standard/Enterprise). No force push. No direct commits. |
| `epic/*` | CI must pass. No force push. |

---

## Verification Checklist

- [ ] Branch name follows naming convention
- [ ] All commits use conventional format (`type(scope): subject`)
- [ ] Subject lines ≤ 72 characters, imperative mood
- [ ] PR title matches conventional commit format
- [ ] PR body includes Summary, Criteria Covered, and Test Plan
- [ ] PR is under 400 lines (or split justification documented)
- [ ] Branch deleted after merge
- [ ] No direct pushes to `main`
