# Stack: Python + FastAPI
**Use for:** Automation tools, data pipelines, COO/ops dashboards, CLI scripts, internal APIs
**Version:** 1.0.0 | **Updated:** 2026-03-15

---

## Scaffold (Run Once to Create Project)

```bash
# 1. Create project directory
mkdir [project-name] && cd [project-name]

# 2. Create virtual environment
python3 -m venv venv
source venv/bin/activate   # Mac/Linux
# venv\Scripts\activate    # Windows

# 3. Install core dependencies
pip install fastapi uvicorn[standard] sqlalchemy psycopg2-binary python-dotenv pydantic

# 4. Install dev dependencies
pip install pytest pytest-asyncio httpx black isort mypy ruff

# 5. Create project structure
mkdir -p src/{api,models,services,db} tests/{unit,integration}
touch src/__init__.py src/main.py src/api/__init__.py src/models/__init__.py
touch src/services/__init__.py src/db/__init__.py
touch .env.example .env requirements.txt requirements-dev.txt

# 6. Freeze dependencies
pip freeze > requirements.txt
```

---

## Daily Commands

| Action | Command |
|--------|---------|
| Dev server (hot reload) | `uvicorn src.main:app --reload` |
| Run all tests | `python -m pytest` |
| Run tests with coverage | `python -m pytest --cov=src --cov-report=term-missing` |
| Lint | `ruff check .` |
| Format | `black .` |
| Type check | `mypy src/` |
| Run a script | `python -m src.[module]` |
| DB migrations (Alembic) | `alembic upgrade head` |
| Generate migration | `alembic revision --autogenerate -m "[description]"` |
| Deploy (Railway) | `railway up` |
| Deploy (Render) | `render deploy` |

---

## Quality Gates (Non-Negotiable)

| Gate | Command | Pass Criteria |
|------|---------|--------------|
| Lint | `ruff check .` | 0 errors |
| Format | `black --check .` | No formatting issues |
| Type check | `mypy src/` | 0 type errors |
| Tests | `python -m pytest` | All tests pass |
| Coverage | `pytest --cov=src` | ≥ 70% (target 80%) |

All gates must pass before Lead Developer writes the Handoff Note.

---

## CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
          cache: 'pip'
      - run: pip install -r requirements.txt -r requirements-dev.txt
      - run: ruff check .
      - run: black --check .
      - run: mypy src/
      - run: python -m pytest --cov=src

  pr-size:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Check PR size
        run: |
          LINES=$(git diff --stat origin/main...HEAD -- . ':!requirements*.txt' ':!*.generated.*' | tail -1 | awk '{print $4+$6}')
          if [ "${LINES:-0}" -gt 400 ]; then
            echo "::error::PR exceeds 400-line limit ($LINES lines changed). Split into smaller PRs."
            exit 1
          fi
```

PR size limit: 400 lines (excludes `requirements*.txt` and generated files).
See `rules/git-workflow.md` for full PR standards.

---

## Directory Structure

```
[project-root]/
├── src/
│   ├── main.py               ← FastAPI app entry point
│   ├── api/
│   │   ├── __init__.py
│   │   ├── routes/           ← One file per resource group
│   │   │   ├── users.py
│   │   │   └── items.py
│   │   └── dependencies.py   ← Shared FastAPI dependencies (auth, DB session)
│   ├── models/
│   │   ├── __init__.py
│   │   └── schemas.py        ← Pydantic request/response models
│   ├── db/
│   │   ├── __init__.py
│   │   ├── base.py           ← SQLAlchemy base
│   │   └── models.py         ← DB table definitions (SCHEMA SOURCE OF TRUTH)
│   └── services/
│       └── [domain].py       ← Business logic, no HTTP concerns
├── tests/
│   ├── unit/
│   └── integration/
├── alembic/                  ← DB migration history
├── .env.example
├── .env                      ← NOT committed
├── requirements.txt
├── requirements-dev.txt
├── SPEC.md
├── SPRINT.md
└── CLAUDE.md                 ← Generated from ~/.claude/templates/PROJECT_CLAUDE.md
```

---

## .env.example Template

```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# App
APP_ENV=development
SECRET_KEY=your-secret-key-here
API_KEY=your-api-key-here

# External integrations (add as needed)
QUICKBASE_TOKEN=your-quickbase-token
ZAPIER_WEBHOOK_URL=https://hooks.zapier.com/...
GOOGLE_SHEETS_KEY=your-key
```

---

## src/main.py Template

```python
from fastapi import FastAPI
from src.api.routes import users, items

app = FastAPI(
    title="[Project Name]",
    version="1.0.0",
    description="[Short description]",
)

app.include_router(users.router, prefix="/users", tags=["users"])
app.include_router(items.router, prefix="/items", tags=["items"])

@app.get("/health")
def health_check():
    return {"status": "ok"}
```

---

## Tech Selection Record Template (paste into SPRINT.md)

```
### Tech Selection Record — [YYYY-MM-DD]
FE: None (API only) / or [add FE stack if needed]
BE: Python 3.11+ + FastAPI + SQLAlchemy + Alembic
DB: PostgreSQL
Schema Source of Truth: src/db/models.py
QA Toolchain: pytest + httpx (integration tests)
Confirmed by: Founder (yes)
```

---

## Deployment Options

| Host | Command | Notes |
|------|---------|-------|
| Railway | `railway up` | Recommended; Dockerfile optional |
| Render | Push to main → auto-deploys | Add `Procfile`: `web: uvicorn src.main:app --host 0.0.0.0 --port $PORT` |
| Fly.io | `fly deploy` | Good for long-running jobs |
| VPS (bare) | `uvicorn src.main:app --host 0.0.0.0 --port 8000` | Use with nginx + systemd |

## Procfile (for Render/Heroku)

```
web: uvicorn src.main:app --host 0.0.0.0 --port $PORT
```
