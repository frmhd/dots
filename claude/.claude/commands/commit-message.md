---
allowed-tools: Bash(git add:*), Bash(git status:*)
description: Create a git commit message
model: claude-haiku-4-5
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

Based on the above changes, create a single git commit message. Use Conventional Commits format.
Return only the commit message itself without any additional text (commit message should be ready for copy-paste)
