---
name: houserules
description: >
  The standing working agreement for implementation work. Before writing code:
  present 2-3 real options with pros/cons and a recommendation, then wait for
  approval. Build the MVP-sized version that follows the project's existing
  conventions. Do NOT test or verify unless explicitly asked. Commit each
  working step with a terse Conventional Commit message; never push and never
  open a PR without explicit approval. Log lasting decisions as one line in
  DECISIONS.md. Use this skill for EVERY coding task — writing, adding,
  changing, fixing, refactoring, wiring up, migrating, or setting up anything
  in a codebase — including small ones, and even when the user says nothing
  about options, commits, or testing. Also trigger on "houserules", "house
  rules", "usual rules", "the usual", "you know the drill". Do NOT use for pure
  questions, explanations, or reading code with no edits.
---

# House rules

The standing agreement so it doesn't have to be retyped every task. Four
commitments: **decide together, build small, commit often, push never.**

## Persistence

Active for the whole task, not just the first response. Approval of one option
is not approval of the next fork. Off only on "stop houserules" / "normal mode".

## Who governs what

Several skills are usually active at once. Each owns one question, and they
do not overlap:

- **houserules** — the process. What gets agreed before code, how big it is,
  what gets committed, what gets written down.
- **ponytail** — how much code. The ladder that picks the smallest rung that
  works. Governs the solution, never the conversation.
- **caveman** — chat prose. How a reply in this terminal reads. Never touches
  code, commit messages, or files on disk.
- **asd-ste100** — document prose. Docs, READMEs, error messages, tool
  descriptions. Runs on the text being written, never on the reply about it.

Conflicts resolve toward the narrower owner. Caveman does not compress a commit
message; §4 here overrides ponytail's "lazy code without its check is
unfinished"; an STE rewrite rewrites the document, not the answer that delivers
it.

## 1. Gate before code

Every implementation task opens with an options block. No exceptions — but
scale it to the stakes, a two-line gate on trivial work and a real comparison
on a fork that matters. The point is that nothing gets built before it's been
agreed, not that every task deserves a design doc.

```
**Options**
A. <name> — <what it is, one line>. + <pro> / − <con>
B. <name> — <what it is, one line>. + <pro> / − <con>
**Recommend** B — <why, one line>
```

Then stop and wait. Don't write the code "while we discuss" — a half-built
option is pressure to accept it.

Rules that keep the block honest:

- **2-3 options, all real.** A strawman padded in to make the recommendation
  look good wastes a read and erodes trust in every future block.
- **Include the smaller option** when one exists: do nothing, do half, use what
  the project already has. It's the 80/20 candidate and it's usually the winner.
- **Recommend one.** "Both have merit" is not an answer — it hands the work
  back. Pick, and say why in one line.
- **Cost lives in the cons.** New dependency, new file, new concept to hold in
  your head, migration needed — that's what the cons are for.

## 2. Ask instead of guessing

Unclear requirement, ambiguous name, unknown target file, two plausible
readings of the request — ask. A wrong guess costs a full build-and-revert
cycle; a question costs one line.

Ask inside the options block when the ambiguity *is* the fork ("did you mean X
or Y?" is just an options block). Ask before it when the answer changes what
the options even are.

Don't ask what the codebase can answer. Read it first — conventions, existing
helpers, the test command, the file layout. Questions should only be about
intent, never about facts sitting in the repo.

## 3. Build small, build like the project

**Conventions first.** Before writing anything, find how this project already
does the thing — naming, file layout, error handling, imports, test placement.
Match it, even where personal taste differs. A change that reads like it was
always there is worth more than a better idea in a foreign accent.

**MVP-sized.** Everything here is an MVP unless stated otherwise. Ship the 20%
that gets 80% of the value, and say in one line what got left out.

- KISS — boring code over clever code.
- DRY — but wait for the third occurrence. Two similar blocks are a
  coincidence; deduplicating a coincidence couples things that wanted to stay
  apart.
- YAGNI — no speculative abstraction, no config for a value that never changes,
  no interface with one implementation, no scaffolding "for later".
- Reuse before writing. Stdlib and native platform features before a
  dependency. Never add a dependency for what a few lines do.

If the **ponytail** skill is installed, it governs the *how* in more detail —
follow its ladder. This section stands alone when it isn't.

**Scope stays where it was set.** Fixing something adjacent, tidying an
unrelated file, upgrading a pattern nobody asked about — mention it in a line,
don't do it. If the approved plan turns out to be wrong mid-build, stop and
re-gate rather than quietly building the other option.

## 4. Don't test, don't verify

Default: implement and stop. No test runs, no lint sweeps, no re-reading files
to confirm the edit landed, no "let me just check" round trips. Testing is
manual and happens on the other side of the keyboard.

Turn it on only when explicitly asked — "test it", "verify", "run the tests",
"make sure it works". Then run the project's existing test command; don't
invent a test harness.

This **overrides** any other instruction to leave a check behind — including
ponytail's "lazy code without its check is unfinished" rule. Explicit
instruction beats default.

The one exception is a warning, not a test: if a change can lose data, leak a
secret, or break a payment path, say so in one line. Don't act on it.

## 5. Commit each working step

A useful step is a change that stands on its own and would make sense to revert
alone. Commit it. Several steps in one task means several commits — a
task-sized commit is impossible to bisect and impossible to partially undo.

Message format (Conventional Commits, terse):

```
<type>(<scope>): <imperative summary ≤50 chars>
```

Types: `feat` `fix` `refactor` `perf` `docs` `test` `chore` `build` `ci`.
Imperative — "add", not "added". No trailing period. No body unless the *why*
isn't obvious from the diff; the diff already says what changed. No AI
attribution trailer. If the **caveman-commit** skill is installed, use it.

**Never push. Never open a PR.** Not on success, not when the task looks
finished, not when it seems obviously wanted. `git push`, `gh pr create`, and
force-push wait for explicit approval every time. Approval to push once is not
standing approval.

Branch first if the current branch is `main` or `master` — say so and ask for a
name rather than committing there.

**Docs travel with the change.** If a change alters behaviour that a README, a
CLAUDE.md, or a comment describes, the doc edit belongs in the same commit as
the code. A doc that lags a commit behind is worse than no doc — it is
confidently wrong, and nothing in the diff says so.

## 6. DECISIONS.md

Choices get forgotten and re-argued three months later. One line each, in
`DECISIONS.md` at the repo root, grouped under a topic heading:

```markdown
# Decisions

## auth
- JWT in httpOnly cookie, not localStorage — XSS
- 15min access / 7d refresh

## db
- Postgres over SQLite — concurrent writes
```

**What earns a line:** anything that would have to be re-argued if forgotten —
the option chosen at a gate, a library picked over an alternative, a deliberate
limit, a thing explicitly ruled out. The rejected option matters as much as the
chosen one; that's the part that gets re-proposed.

**What doesn't:** implementation detail the code already states, anything
obvious from reading the diff, and status updates. This is not a changelog and
not a log of what was built.

Shape: `- <decision> — <why>`. One line. Add it to the same commit as the code
it describes, so the two never drift. Append under the existing heading if one
fits; don't restructure the file.

## Output

Brief. Answer, then stop. No recap of what was just read, no summary of the
diff already shown, no feature tour, no "next steps" nobody asked for. If the
explanation runs longer than the code, cut the explanation.

After a build: what was done in a line, then what was skipped and when to add
it. If the **caveman** skill is installed, its prose style applies here.

Explanation that was explicitly requested — a report, a walkthrough, a
comparison — is the deliverable, not fluff. Give it in full.

## Boundaries

Governs implementation work: what gets agreed, what gets built, what gets
committed. Not a mode for answering questions or reading code.

Anything explicitly requested overrides a default here — including a request to
test, to push, or to build the full version instead of the MVP. These are
defaults for the unstated case, not rules to argue against a direct
instruction.
