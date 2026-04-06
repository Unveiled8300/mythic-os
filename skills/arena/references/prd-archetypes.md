# PRD Archetypes for Arena Matchups

Pre-built task + criteria bundles for the "compare systems building apps" use case.
Each archetype provides a standardized one-page PRD prompt and matching scoring criteria.

## How to Use

When a user wants to compare Claude Code systems (or any system that builds apps):
1. Pick an archetype below
2. Use the `prompt` as the arena task
3. Use the `criteria` as the arena scoring criteria
4. Optionally customize weights

---

## B2C: Task Tracker with Auth

**ICP:** Individual productivity user, 25-40, wants simple task management

**Prompt:**
```
Build a task tracker web app with the following requirements:
- User authentication (sign up, log in, log out)
- Create, read, update, delete tasks
- Tasks have: title, description, due date, priority (low/medium/high), status (todo/in-progress/done)
- Filter tasks by status and priority
- Responsive design that works on mobile and desktop
- Pleasant, modern UI with a color scheme appropriate for a productivity tool

Use Next.js with TypeScript. Include a README with setup instructions.
Do NOT use a real database — use local storage or in-memory state for this prototype.
```

**Criteria:**
```yaml
- { name: "builds", type: binary, evaluator: "cd $OUTPUT_DIR && npm install && npm run build", weight: 0.20 }
- { name: "has-auth", type: binary, evaluator: "grep -rl 'sign.*up\\|login\\|auth' $OUTPUT_DIR/src/", weight: 0.15 }
- { name: "has-crud", type: binary, evaluator: "grep -rl 'create\\|delete\\|update' $OUTPUT_DIR/src/", weight: 0.15 }
- { name: "responsive", type: binary, evaluator: "grep -rl 'viewport\\|@media\\|md:\\|sm:' $OUTPUT_DIR/src/", weight: 0.10 }
- { name: "lint-clean", type: binary, evaluator: "cd $OUTPUT_DIR && npx eslint . --max-warnings=0 2>/dev/null; test $? -le 1", weight: 0.10 }
- { name: "code-quality", type: rubric, evaluator: "Rate 1-5: Is this code well-structured with clear component separation and TypeScript types? Answer ONLY the number.", scale: 5, weight: 0.15 }
- { name: "ui-quality", type: rubric, evaluator: "Rate 1-5: Does this UI look modern, clean, and appropriate for a productivity app? Consider layout, spacing, color, and usability. Answer ONLY the number.", scale: 5, weight: 0.15 }
```

---

## B2C Viral: Recipe Sharing

**ICP:** Home cook, 20-45, shares recipes with friends, wants social engagement

**Prompt:**
```
Build a recipe sharing web app with the following requirements:
- Users can post recipes (title, ingredients list, steps, cook time, photo placeholder)
- Browse feed of all recipes sorted by newest
- Like/heart recipes
- Share button (generates a shareable link)
- Search by recipe name or ingredient
- Responsive mobile-first design
- Fun, warm, food-appropriate color scheme

Use Next.js with TypeScript. In-memory state, no real database.
Include a README with setup instructions.
```

**Criteria:**
```yaml
- { name: "builds", type: binary, evaluator: "cd $OUTPUT_DIR && npm install && npm run build", weight: 0.20 }
- { name: "has-feed", type: binary, evaluator: "grep -rl 'feed\\|recipe.*list\\|browse' $OUTPUT_DIR/src/", weight: 0.15 }
- { name: "has-social", type: binary, evaluator: "grep -rl 'like\\|heart\\|share' $OUTPUT_DIR/src/", weight: 0.15 }
- { name: "has-search", type: binary, evaluator: "grep -rl 'search\\|filter\\|query' $OUTPUT_DIR/src/", weight: 0.10 }
- { name: "mobile-first", type: binary, evaluator: "grep -rl 'sm:\\|mobile\\|@media' $OUTPUT_DIR/src/", weight: 0.10 }
- { name: "code-quality", type: rubric, evaluator: "Rate 1-5: Is this code well-structured? Answer ONLY the number.", scale: 5, weight: 0.15 }
- { name: "ui-quality", type: rubric, evaluator: "Rate 1-5: Does this UI feel warm, inviting, and food-appropriate? Answer ONLY the number.", scale: 5, weight: 0.15 }
```

---

## B2B Enterprise: Invoice Dashboard with RBAC

**ICP:** Finance team at mid-market company, needs clear data and role separation

**Prompt:**
```
Build an invoice management dashboard with the following requirements:
- Role-based access: Admin (full access), Manager (view + approve), Viewer (read-only)
- Invoice list with columns: number, client, amount, status (draft/pending/approved/paid), date
- Create new invoice form
- Approve/reject workflow for managers
- Summary stats: total outstanding, total paid, overdue count
- Data table with sorting and pagination
- Professional, enterprise-appropriate UI (clean, minimal, high information density)

Use Next.js with TypeScript. Mock data, no real database.
Include a README with setup instructions.
```

**Criteria:**
```yaml
- { name: "builds", type: binary, evaluator: "cd $OUTPUT_DIR && npm install && npm run build", weight: 0.15 }
- { name: "has-rbac", type: binary, evaluator: "grep -rl 'role\\|admin\\|manager\\|permission\\|auth' $OUTPUT_DIR/src/", weight: 0.20 }
- { name: "has-workflow", type: binary, evaluator: "grep -rl 'approve\\|reject\\|pending' $OUTPUT_DIR/src/", weight: 0.15 }
- { name: "has-stats", type: binary, evaluator: "grep -rl 'total\\|outstanding\\|overdue\\|summary' $OUTPUT_DIR/src/", weight: 0.10 }
- { name: "has-table", type: binary, evaluator: "grep -rl 'sort\\|pagination\\|table' $OUTPUT_DIR/src/", weight: 0.10 }
- { name: "code-quality", type: rubric, evaluator: "Rate 1-5: Is this code well-structured with proper TypeScript types and separation of concerns? Answer ONLY the number.", scale: 5, weight: 0.15 }
- { name: "ui-quality", type: rubric, evaluator: "Rate 1-5: Does this UI look professional and enterprise-appropriate with high information density and clear hierarchy? Answer ONLY the number.", scale: 5, weight: 0.15 }
```

---

## B2B2C: Marketplace with Buyer/Seller

**ICP:** Platform operator connecting sellers to buyers

**Prompt:**
```
Build a simple marketplace web app with the following requirements:
- Two user types: Seller and Buyer
- Sellers can list items (title, description, price, category, image placeholder)
- Buyers can browse, search, and filter items by category/price
- Item detail page with seller info
- Shopping cart for buyers
- Seller dashboard showing their listings and stats
- Clean, trustworthy marketplace UI

Use Next.js with TypeScript. In-memory state, no real database.
Include a README with setup instructions.
```

**Criteria:**
```yaml
- { name: "builds", type: binary, evaluator: "cd $OUTPUT_DIR && npm install && npm run build", weight: 0.15 }
- { name: "dual-persona", type: binary, evaluator: "grep -rl 'seller\\|buyer\\|vendor\\|customer' $OUTPUT_DIR/src/", weight: 0.20 }
- { name: "has-listings", type: binary, evaluator: "grep -rl 'listing\\|product\\|item.*create' $OUTPUT_DIR/src/", weight: 0.15 }
- { name: "has-cart", type: binary, evaluator: "grep -rl 'cart\\|basket\\|checkout' $OUTPUT_DIR/src/", weight: 0.10 }
- { name: "has-search", type: binary, evaluator: "grep -rl 'search\\|filter\\|category' $OUTPUT_DIR/src/", weight: 0.10 }
- { name: "code-quality", type: rubric, evaluator: "Rate 1-5: Is this code well-structured? Answer ONLY the number.", scale: 5, weight: 0.15 }
- { name: "ui-quality", type: rubric, evaluator: "Rate 1-5: Does this UI feel trustworthy and professional for a marketplace? Answer ONLY the number.", scale: 5, weight: 0.15 }
```

---

## Personal Tool: CLI Expense Tracker

**ICP:** Developer tracking personal expenses from the terminal

**Prompt:**
```
Build a CLI expense tracker in Python with the following requirements:
- Add expense: amount, category, description, date (default today)
- List expenses with optional filters (date range, category)
- Summary by category for a given month
- Export to CSV
- Data persisted in a local JSON file
- Clean, well-documented code with type hints
- Include tests

Use Python 3.11+. Include requirements.txt and README.
```

**Criteria:**
```yaml
- { name: "runs", type: binary, evaluator: "cd $OUTPUT_DIR && python3 -c 'import importlib; importlib.import_module(\"expense_tracker\")' 2>/dev/null || python3 main.py --help 2>/dev/null", weight: 0.20 }
- { name: "has-crud", type: binary, evaluator: "grep -rl 'add\\|list\\|delete\\|export' $OUTPUT_DIR/*.py $OUTPUT_DIR/**/*.py 2>/dev/null", weight: 0.15 }
- { name: "has-tests", type: binary, evaluator: "find $OUTPUT_DIR -name 'test_*.py' -o -name '*_test.py' | grep -q .", weight: 0.15 }
- { name: "has-types", type: binary, evaluator: "grep -rl ':\\s*\\(str\\|int\\|float\\|list\\|dict\\|Optional\\)' $OUTPUT_DIR/*.py 2>/dev/null", weight: 0.10 }
- { name: "has-persistence", type: binary, evaluator: "grep -rl 'json\\|sqlite\\|csv.*write' $OUTPUT_DIR/*.py 2>/dev/null", weight: 0.10 }
- { name: "code-quality", type: rubric, evaluator: "Rate 1-5: Is this Python code clean, well-typed, and Pythonic? Answer ONLY the number.", scale: 5, weight: 0.20 }
- { name: "loc-efficiency", type: numeric, evaluator: "find $OUTPUT_DIR -name '*.py' | xargs wc -l | tail -1 | awk '{print $1}'", direction: lower, weight: 0.10 }
```

---

## Static: Portfolio with Gallery

**ICP:** Creative professional showcasing work

**Prompt:**
```
Build a portfolio website with the following requirements:
- Hero section with name, title, and brief intro
- Projects gallery with grid layout (6+ placeholder projects with title, description, thumbnail placeholder)
- About page with bio
- Contact section with email link and social media placeholders
- Responsive design, looks great on all devices
- Elegant, minimal design with good typography
- Fast loading, no unnecessary JavaScript

Use Astro or plain HTML/CSS/JS. Include a README.
```

**Criteria:**
```yaml
- { name: "builds", type: binary, evaluator: "cd $OUTPUT_DIR && (npm run build 2>/dev/null || test -f index.html)", weight: 0.20 }
- { name: "has-sections", type: binary, evaluator: "grep -rl 'hero\\|projects\\|about\\|contact' $OUTPUT_DIR/src/ $OUTPUT_DIR/*.html 2>/dev/null", weight: 0.15 }
- { name: "responsive", type: binary, evaluator: "grep -rl 'viewport\\|@media\\|md:\\|grid\\|flex' $OUTPUT_DIR/src/ $OUTPUT_DIR/*.html $OUTPUT_DIR/*.css 2>/dev/null", weight: 0.15 }
- { name: "minimal-js", type: binary, evaluator: "JS_SIZE=$(find $OUTPUT_DIR/dist $OUTPUT_DIR -name '*.js' -not -path '*/node_modules/*' 2>/dev/null | xargs wc -c 2>/dev/null | tail -1 | awk '{print $1}'); test ${JS_SIZE:-0} -lt 50000", weight: 0.10 }
- { name: "code-quality", type: rubric, evaluator: "Rate 1-5: Is this code clean and semantic HTML? Answer ONLY the number.", scale: 5, weight: 0.15 }
- { name: "design-quality", type: rubric, evaluator: "Rate 1-5: Does this portfolio look elegant, minimal, and professional with good typography and spacing? Answer ONLY the number.", scale: 5, weight: 0.25 }
```
