---
name: sop-creator
description: Create runbooks, playbooks, and technical documentation that people actually follow
triggers:
  - "create a runbook for"
  - "document this process"
  - "write a playbook"
  - "create operational docs"
  - "formalize technical procedures"
---

# SOP Creator

Create runbooks, playbooks, and technical documentation that people actually follow.

## Core Philosophy

Nobody reads 50-page docs. Make it scannable, actionable, and impossible to misunderstand.

## Document Types

**Tech/Engineering:**
- Runbook
- Deployment Playbook
- Troubleshooting Guide
- How-To
- ADR

**Operations/Business:**
- Process SOP
- Checklist
- Decision Tree
- Handoff Doc

**Content/Creative:**
- Production Workflow
- Review Process
- Publishing Checklist

**General:**
- Standard SOP
- Quick Reference
- Onboarding Guide

## Universal Structure

1. **Definition of Done** (checklist - most important, put near the top)
2. **When to Use This**
3. **Prerequisites**
4. **The Process** (numbered steps)
5. **Verify Completion**
6. **When Things Go Wrong**
7. **Questions?**

## Writing Rules

- **Be specific** — numbers, names, thresholds, not "as needed" or "regularly"
- **Action-first steps** — verbs, not descriptions
- **Warnings come first** — before the dangerous step, not after
- **Clear decision points** — if X, then Y, not "handle based on priority"

## Output Format

Documents are generated as `.md` files with:
- Clear headings and subheadings
- Numbered step sequences for procedures
- Tables for decision matrices and prerequisites
- Code blocks for commands and examples
- Bold text for critical warnings and important notes
- Checkboxes for verification steps

## Tips for Best Results

- Start with the Definition of Done - this keeps the document focused
- Use exact command syntax, not descriptions
- Include expected output and failure modes
- Link to related docs when relevant
- Keep warnings prominent and unambiguous
