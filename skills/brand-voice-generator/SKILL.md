---
name: brand-voice-generator
description: Create brand system and tone-of-voice files that power presentations and guide all content generation
triggers:
  - "help me create a brand system"
  - "generate my tone of voice"
  - "set up my brand for presentations"
  - "create brand files"
---

# Brand & Voice Generator

Generate tone-of-voice and brand-system files that power the PPTX Generator and can guide customization of all other skills.

## Core Philosophy

Your brand and voice should be documented once and reused everywhere. The files this skill creates become the source of truth for all content generation.

## What This Creates

| File | Purpose | Used By |
|------|---------|---------|
| `brand.json` | Colors, fonts, assets | PPTX Generator |
| `config.json` | Output settings | PPTX Generator |
| `brand-system.md` | Design philosophy & guidelines | All skills |
| `tone-of-voice.md` | Writing voice & personality | PPTX content, SOPs |

## Process Overview

1. **Gather Brand Basics** - Name, description, primary use case
2. **Define Colors** - 10 color values for the complete system
3. **Define Typography** - Heading, body, and code fonts
4. **Define Assets** - Logo and icon paths
5. **Discover Voice** - Personality, vocabulary, sentence patterns
6. **Create Design Philosophy** - Core principles and signature elements
7. **Generate Files** - Create all four files with gathered information

## Voice Templates Included

The skill includes 5 example voice configurations to help you discover your own:

- **Technical Educator** - Enthusiastic expert who teaches by showing
- **Calm Authority** - Confident and measured, lets expertise speak through specifics
- **Builder's Perspective** - Developer-to-developer, unfiltered opinions backed by code
- **Approachable Expert** - Makes the complex accessible without dumbing it down
- **Contrarian Thinker** - Challenges conventional wisdom with evidence

## Output Format

All files are saved to `brands/[your-brand-name]/` directory with this structure:

```
brands/your-brand-name/
├── brand.json
├── config.json
├── brand-system.md
├── tone-of-voice.md
└── assets/
    └── logo.png (or your logo file)
```
