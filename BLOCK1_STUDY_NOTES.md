 Block 1 Study Notes — SSH, Git, and Docker (In Progress)
Personal reference notes from our sessions. Written to be re-read and self-tested against, not just skimmed once.

---

## 1. SSH Keys — Why and How

### The Problem SSH Keys Solve
Password-based auth means typing/transmitting a secret every time, which creates more chances for it to leak (phishing, logging, interception). SSH keys avoid this entirely.

### The Mechanism (Asymmetric Cryptography)
- **Private key** — stays on your machine, never leaves, never shared.
- **Public key** — uploaded to GitHub (or any server you connect to).

**The actual handshake:**
1. You try to connect to GitHub over SSH.
2. GitHub sees your public key on file and sends back a cryptographic challenge — data only decryptable by the matching private key.
3. Your machine uses the private key to solve the challenge.
4. GitHub grants access — **your private key never crosses the network.**

### Common Misconception (Correction)
SSH is **not primarily about speed.** It's about security + convenience (no retyping a password every push), and it's now required since GitHub deprecated HTTPS password auth entirely.

### Key File Naming
- `id_ed25519` / `id_rsa` → **private** key (no extension)
- `id_ed25519.pub` / `id_rsa.pub` → **public** key (`.pub` = safe to share)
- `id_ed25519` is the modern, preferred algorithm over the older `id_rsa`.

### File Permissions (Critical Detail)
Reading `-rw-------`: three groups of three characters after the leading file-type marker (`-`):
- Owner: `rw-` = read(4) + write(2) + none(0) = **6**
- Group: `---` = **0**
- Others: `---` = **0**

So `id_ed25519` (private key) = **600**. `id_ed25519.pub` (public key, `-rw-r--r--`) = **644**.

**Why this matters practically:** SSH will *refuse to use* a private key if its permissions are too open (e.g. accidentally `chmod 777`'d). Fix: `chmod 600 ~/.ssh/id_ed25519`.

### Testing the Connection
```bash
ssh -T git@github.com
```
**Success looks like:**
```
Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.
```
This is *not* an error — GitHub confirms your identity but doesn't give shell access (which would be a security risk). It's only used to authorize git operations (push/pull).

**Failure looks like:** `Permission denied (publickey)` — meaning your public key isn't uploaded to GitHub, or the wrong key is being offered locally.

---

## 2. Git — Merge vs Rebase

### The Setup: Diverged History
Starting point — a branch created from `main` at commit A, then both sides move forward independently:
```
A --- F --- G       (main)
 \
  D --- E           (feature-branch)
```

### `git merge main` (while on feature-branch)
Creates a **new commit with two parents** — ties the two histories together without changing anything that already existed.

**Result:**
```
A --- F --- G          (main)
 \           \
  D --- E --- M        (feature-branch)  ← M = merge commit
```
- D and E keep their **original commit hashes** — untouched.
- History shows the true, honest shape of what happened: two lines diverged, then joined.
- **Important nuance:** only `feature-branch` moves after `git merge main`. `main` itself stays exactly where it was (at G) — merge is one-directional. To get changes into `main`, you'd merge in the other direction (or via a PR).

### `git rebase main` (while on feature-branch)
**Replays** your commits one at a time on top of the new base, as if your work started *after* the latest main changes.

**Result:**
```
A --- F --- G --- D' --- E'      (feature-branch, one straight line)
```
- D and E get **entirely new commit hashes** (content similar, but different objects to git).
- History looks clean and linear — but it's rewriting what actually happened.

### The One-Sentence Summary
**Merge preserves true history and adds a joining commit. Rebase rewrites history to look like a straight line — it's a "lie" about the order things really happened in.**

### The Golden Rule
**Rebase freely on local, unpushed commits** — totally safe, nobody else has a copy yet.
**Never rebase commits that are already pushed/shared** — if a teammate already pulled the old commits, and you rebase + force-push new ones, their local history now references commits that no longer exist on the remote.

**What actually breaks (the precise mechanism, not just "conflicts"):** it's not a normal merge-conflict situation. The teammate's local branch trusts commits that have been replaced. The fix isn't `rebase --continue` or a normal merge — it requires the teammate to **discard their local copy and resync** from the new remote history, potentially losing any of their own work built on the old commits. This is genuinely disruptive, which is why the rule exists.

### Common Real-World Team Convention
- **Rebase locally, before opening a PR** — squash/clean up messy WIP commits ("oops," "wip," "fix typo") into meaningful ones, since it's still private and safe to rewrite.
- **Merge (not rebase) when integrating an approved PR into main** — preserves an honest record of when the feature was integrated, without erasing the fact it was its own line of work.
- **Why this combination specifically:** messy commit history becomes *permanent* once merged into main — and tools like `git bisect` (see below) will surface those messy commit messages ("wip," "oops") to anyone debugging later, which is nearly useless information. Clean commits locally = useful history forever.

### Reading Conflict Markers
```
line 1
<<<<<<< HEAD
line 2 from feature
=======
line 2 from main
>>>>>>> main
```
- `<<<<<<< HEAD` → your current branch's version
- `=======` → divider
- `>>>>>>> main` → the incoming branch's version (labeled by name)

**Important twist during rebase:** `HEAD` temporarily refers to the *new base* (e.g. main) you're replaying onto — not your original branch. This is the reverse of a normal merge conflict, because rebase temporarily reframes things as "pretend I'm building on top of main." Don't get tripped up by this — always check which label (`HEAD` vs the branch name) is attached to which block.

### Resolving a Conflict
1. Open the file, manually edit out the markers, decide the final correct content.
2. Merge: `git add <file>` then `git commit`.
3. Rebase: `git add <file>` then `git rebase --continue` (this may open a commit-message editor since rebase manages committing per replayed commit — save and exit as normal, e.g. nano: `Ctrl+O`, Enter, `Ctrl+X`).

**Rebase conflicts can cascade *or* resolve themselves** as you go — since each replayed commit builds on the *already-resolved* version of the file, later commits may apply cleanly even if earlier ones conflicted.

### Escape Hatches
- `git rebase --abort` — cancels an in-progress rebase entirely, returns your branch to exactly where it was before you ran `git rebase main`. Only works *during* an active rebase.
- `git merge --abort` — equivalent escape hatch for an in-progress merge conflict.

---

## 3. Git Bisect

### The Concept: Binary Search for Bugs
**Naive approach:** checking commits one at a time (up to N checks for N commits).
**Bisect's approach:** binary search — check the *middle* commit, then halve the remaining search space each time.

**Math to remember:**
- 100 commits → ~7 checks (2^7 = 128)
- 500 commits → ~9 checks (500 → 250 → 125 → 63 → 32 → 16 → 8 → 4 → 2 → 1)
- 1000 commits → ~10 checks (2^10 = 1024)

**Key insight: this is logarithmic growth, not linear.** Doubling the commit count barely increases the number of checks needed — this is *why* bisect is dramatically faster than manual checking or reading every diff.

### When to Actually Use Bisect (the real trigger condition)
Two things must both be true:
1. **You don't already know which commit caused the bug** — it could be anywhere across a large, unknown range of history.
2. **You have a reliable, clear pass/fail test** for any given commit (automated test, reproducible steps, or a script — `git bisect run <script>` can even fully automate this).

If you already know exactly which recent change broke something, you don't need bisect — you already know where to look.

### The Workflow
```bash
git bisect start
git bisect bad                    # mark current commit as broken
git bisect good <known-good-hash> # mark a commit you know worked
```
Git automatically checks out the midpoint commit. Test it, then tell git the result:
```bash
git bisect good     # if this commit works fine
git bisect bad       # if this commit is broken
```
Repeat until git reports:
```
<hash> is the first bad commit
```

### The Skip Command (Edge Case)
```bash
git bisect skip
```
**When to use it:** when a commit genuinely **cannot be tested** — e.g., it fails to even build/compile for unrelated reasons (a missing dependency at that point in history), not because of the bug you're hunting.

**Why it's needed (the precise reasoning):** bisect's whole method depends on answering "good or bad" for every commit it shows you. Some commits are neither — they're simply **untestable** (mid-refactor, broken build unrelated to your bug). `skip` handles "the good/bad question doesn't even apply here," and tells git to pick a different nearby commit instead. Without it, you'd be stuck.

**Caveat:** if too many consecutive commits get skipped, bisect may fail to pinpoint one exact commit and instead report a range — but occasional skips work cleanly.

### Cleanup
```bash
git bisect reset
```
Exits bisect mode, returns you to your normal branch at the latest commit (bisect leaves you in a "detached HEAD" state during the search).

---

## 4. Docker — Introduction (In Progress)

### The Problem Docker Solves
**"It works on my machine"** — code that runs fine on your setup can break entirely on someone else's, even with zero code changes, because of differences in:
- Operating system
- Software/library versions
- Missing dependencies
- Configuration (env vars, paths, settings)

**One-sentence definition to remember:**
> Docker solves the problem of code working on one machine but not working on another, because of differences in OS, software versions, and missing dependencies/configuration.

### Core Concepts (So Far)
- **Image** — a packaged, frozen "recipe": your app's code + exact OS layer + dependencies + config, all bundled into one file. Inert by itself — doesn't run anything, just the blueprint.
- **Container** — a **running instance** of an image. Isolated from everything else on the host machine.

**Analogy to build on (started, not finished):** image is like a recipe/class; container is like the actual meal made from it / an object instantiated from that class. *(We stopped here — pick this up next session before moving to writing actual Dockerfiles.)*

---

## What's Next
- Finish the image vs. container analogy
- Write 3 Dockerfiles from scratch (static site, Python script, Node app) — no templates
- Deliberately break a container and diagnose/fix it
- Then: Docker Compose, Kubernetes basics (Block 5-7 territory)

---

## How to Use These Notes for Self-Testing
Don't just re-read passively. Try:
1. Covering the "result" sections and predicting them from the setup alone.
2. Explaining each concept out loud, from memory, before checking against these notes.
3. For Git specifically: actually redo the merge/rebase/bisect exercises in a scratch repo without looking, then compare.
