---
name: map-codebase
description: >
  Analyze and map an existing codebase for brownfield onboarding. Generates a structured
  CODEBASE.md with tech stack, architecture, key files, dependencies, and gap analysis
  against SPEC.md (if present).
version: 1.0.0
slash_command: /map-codebase
trigger_pattern: "map codebase|map the codebase|analyze codebase|brownfield|onboard to repo"
---

# Skill: Map Codebase

Map an existing repository before building on it. Produces a structured overview so that
development roles start with full context instead of guessing at architecture.

---

## SOP 1: Repository Scan

**When:** First step on any existing codebase.

1. Detect tech stack by scanning for marker files:
   | Marker | Stack |
   |--------|-------|
   | `package.json` | Node.js / JavaScript / TypeScript |
   | `requirements.txt` / `pyproject.toml` | Python |
   | `go.mod` | Go |
   | `Cargo.toml` | Rust |
   | `pom.xml` / `build.gradle` | Java / Kotlin |
   | `prisma/schema.prisma` | Prisma ORM |
   | `docker-compose.yml` | Docker services |

2. Count files by type and measure lines of code:
   ```bash
   find . -type f -name '*.ts' -o -name '*.tsx' -o -name '*.py' -o -name '*.go' | head -500
   wc -l $(find . -path ./node_modules -prune -o -type f -name '*.ts' -print) 2>/dev/null | tail -1
   ```

3. Identify entry points:
   - `src/main.*`, `src/index.*`, `src/app.*`
   - `package.json` → `scripts.start`, `scripts.dev`
   - `Procfile`, `Dockerfile` CMD/ENTRYPOINT

---

## SOP 2: Architecture Mapping

1. Map directory structure to functional areas:
   ```bash
   find . -type d -not -path '*/node_modules/*' -not -path '*/.git/*' -maxdepth 3
   ```

2. Classify directories:
   | Pattern | Area |
   |---------|------|
   | `src/api/`, `routes/`, `controllers/` | API layer |
   | `src/models/`, `db/`, `prisma/` | Data layer |
   | `src/services/`, `lib/` | Business logic |
   | `src/components/`, `pages/`, `views/` | UI layer |
   | `tests/`, `__tests__/`, `spec/` | Test layer |
   | `public/`, `static/`, `assets/` | Static assets |

3. Detect patterns:
   - Routing strategy (file-based, explicit, decorator-based)
   - State management (Redux, Zustand, Context, Pinia)
   - Authentication pattern (JWT, session, OAuth, Supabase Auth)
   - Database access pattern (ORM, raw SQL, query builder)

---

## SOP 3: Dependency Analysis

1. List external dependencies with versions:
   ```bash
   cat package.json | jq '.dependencies, .devDependencies'   # Node
   pip list --format=json                                      # Python
   ```

2. Flag concerns:
   - Outdated major versions (compare against latest)
   - Known vulnerable packages (`npm audit` / `pip-audit`)
   - Duplicate functionality (e.g., both axios and fetch wrappers)
   - Unused dependencies (installed but never imported)

3. Map internal module relationships:
   - Which modules import from which
   - Circular dependency detection
   - Shared utility usage

---

## SOP 4: Gap Analysis (requires SPEC.md)

**Skip if no SPEC.md exists at the project root.**

1. Read SPEC.md Sections 1 (Functional Requirements) and 6 (Definition of Done)
2. For each FR: search the codebase for implementation evidence
3. Classify each requirement:
   | Status | Meaning |
   |--------|---------|
   | `IMPLEMENTED` | Code exists that satisfies the requirement |
   | `PARTIAL` | Some code exists but incomplete |
   | `MISSING` | No implementation found |
   | `NEEDS_REFACTOR` | Implementation exists but does not meet quality gates |

4. Report the gap summary with file references

---

## SOP 5: Generate CODEBASE.md

Write `[project-root]/CODEBASE.md`:

```markdown
# Codebase Map: [Project Name]
Generated: [ISO timestamp] | Tool: /map-codebase v1.0.0

## Tech Stack
- Language: [detected]
- Framework: [detected]
- Database: [detected or N/A]
- Auth: [detected or N/A]

## Architecture
| Area | Directory | Key Files |
|------|-----------|-----------|
| [area] | [path] | [files] |

## Entry Points
- [path] — [purpose]

## Dependencies
- [N] production, [N] dev
- Concerns: [list or "none"]

## Test Coverage
- Framework: [detected]
- Test files: [count]
- Pattern: [unit / integration / e2e / mixed]

## Gap Analysis (vs SPEC.md)
| Requirement | Status | Evidence |
|------------|--------|----------|
| FR-[N] | [status] | [file:line or "not found"] |

(Section omitted if no SPEC.md exists)
```

---

## Usage Patterns

```
# Map a new repo you just cloned
cd ~/projects/client-app && /map-codebase

# Map before writing a SPEC.md (understand what exists)
/map-codebase
# Then: /product-brief (informed by CODEBASE.md)

# Map to find gaps against an existing SPEC.md
/map-codebase
# CODEBASE.md Gap Analysis section shows what's missing
```

---

## Verification Checklist

- [ ] Tech stack correctly identified
- [ ] Directory structure mapped to functional areas
- [ ] Entry points identified
- [ ] Dependencies listed with concerns flagged
- [ ] Gap analysis completed (if SPEC.md exists)
- [ ] CODEBASE.md generated at project root
