---
name: oopsies-triage-and-fix
description: |
  Triage exceptions from the Oopsie error tracker for the current project, pick
  the most urgent one (or the cluster that fits in a single PR), mark it resolved,
  fix it, then run /review, /qa, /ship, and /land without stopping. Use when the
  user says "triage oopsies", "fix the exceptions", "handle production errors",
  "clean up oopsie", "fix prod bugs", or any request that means "look at what's
  broken in prod and actually fix it end-to-end."
---

# Oopsie Triage and Fix

You have access to a skill called Oopsie. It's a self-hosted exception handler like rollbar. You have the ability to see them for different projects, and you can read about that in the oopsie skill.

For this skill, "Oopsie Triage and Fix", you have the ability to handle looking at what exceptions have thrown, figuring out which is most urgent, figuring out which can be fixed on a single PR, and doing the fix and resolving everything. Here is how you'll do it:

## 1. Locate the project

Figure out what project you are in (e.g. `pwd`). Say you're in 'RcMap' — run `oopsie projects` and look for a matching project name on the server. If you find one, scope to it (`oopsie errors --project RcMap`) and list exceptions. If nothing matches, tell the user you can't match the current codebase to an Oopsie project and ask what they want to do. If there's no Oopsie connection at all yet, run the setup flow from the oopsie skill first.

## 2. Group similar bugs

Next, you need to see if some bugs are similar, like 404's of different paths throwing exceptions — those could be handled in a single PR. But a sql exception and a library extension and a nil error, all separate PRs. You'll want to use logic like this, and come up with a suggestion.

- **If there is only one exception, skip this!** Just tell the user you see one exception and you're going to start on it!
- **If you see multiple**, jump to step 3.

## 3. Pick the most urgent

Now, if you see multiple, and one is CLEARLY super urgent, you start there. Like 10k instances, happening every minute, recent as 1 minute ago, FIX THIS NOW.

But if you don't have a clear idea, suggest something and ask the user what they prefer in multiple choice format with a button they can tap to give the answer for the order. If they choose an order, you are just getting the FIRST — they will have to open another work session to do the next priority fix.

## 4. Start the fix

Next you start working on it. When you start working on it, **mark it as resolved in Oopsie** so another user doesn't go try to fix the same issue! Go ahead and do a fix like you normally would.

## 5. Go all the way without stopping

**You NEED TO DO ALL OF THIS WITHOUT STOPPING** — after you fix it, you're going to run the skill `/review`, and then `/qa`, and then `/ship`, and then `/land` (or get it merged when CI passes).

## 6. Success

If you did this right, and there was only one bug, you just found it, resolved it in oopsie, fixed it, reviewed it, qa'd it, and got it merged, and it's deploying on merge — or you found deploy instructions for the project that said otherwise. Good job! This is success!

**A lot of chatting and questions is not success, that's not a great UX.**
