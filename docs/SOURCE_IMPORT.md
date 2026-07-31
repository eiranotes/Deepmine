# Source Import Guide

> Status: **blocking prerequisite**. Backlog task M0-01.
> Audience: whoever has the DeepMine Xcode project on their local machine.

## 1. Why this document exists

The planning documents in this repository (`PRODUCT_SPEC.md`, `TECHNICAL_PLAN.md`,
`IMPLEMENTATION_BACKLOG.md`) were written against an **empty repository**. They describe
the target game, but they could not describe the code being pivoted, because that code has
never been pushed.

The repository currently contains documentation only:

```text
README.md
.gitignore
docs/
```

No `.xcodeproj`, no `.xcworkspace`, no `.swift` files, no assets.

Every reuse decision in the pivot — which persistence layer survives, whether the mine
scene is SpriteKit or SwiftUI, which of the existing services carry over, how much of the
Pomodoro app is deleted versus rewritten — depends on facts that can only be read off the
real source. Until the import happens, planning past this point produces guesses.

A cloud/CI session cannot perform this import. It has no access to a local machine's disk.
**The import must be run by a human on the machine that holds the project.**

## 2. Import procedure

Run these on the machine that has the DeepMine folder.

### 2.1 Confirm what will be committed

```sh
cd /path/to/DeepMine          # the folder containing DeepMine.xcodeproj
ls -la
```

Expect an `.xcodeproj` or `.xcworkspace`, an app source folder, and probably a test folder.

### 2.2 Attach the remote

If the local folder is **not yet a git repository**:

```sh
git init
git remote add origin https://github.com/eiranotes/Deepmine.git
git fetch origin
git checkout -b import/pre-pivot-baseline origin/main
```

If the local folder **is already a git repository** with its own history worth keeping:

```sh
git remote add origin https://github.com/eiranotes/Deepmine.git
git fetch origin
git checkout -b import/pre-pivot-baseline
```

Keeping the existing history is preferred — it preserves the record of how the Pomodoro app
was built, which is useful when deciding what to reuse.

### 2.3 Install the ignore rules before the first `git add`

Copy this repository's `.gitignore` into the project root **first**. Adding it after a
`git add -A` means DerivedData and user state are already staged, and untangling that is
more work than doing it in the right order.

```sh
curl -o .gitignore \
  https://raw.githubusercontent.com/eiranotes/Deepmine/main/.gitignore
```

### 2.4 Verify the staged set before committing

```sh
git add -A
git status --short
git diff --cached --stat | tail -5
```

Check the staged list against these rules:

| Must be included | Must be excluded |
|---|---|
| `*.xcodeproj/project.pbxproj` | `xcuserdata/`, `DerivedData/`, `build/` |
| `*.xcodeproj/xcshareddata/xcschemes/*` (CI needs a shared scheme) | `*.mobileprovision`, `*.p12`, `*.cer` |
| All `.swift` sources | `.env`, API keys, any credential plist |
| `Assets.xcassets`, audio, fonts | `.DS_Store` |
| `*.lproj` / `*.xcstrings` localization | `*.xcresult/` |
| `Package.resolved` (pins dependency versions) | `.build/`, `Pods/`, `Carthage/Build/` |
| Test targets | |

Two checks worth running explicitly, because both are painful to undo after a push:

```sh
# 1. No credential material staged.
git diff --cached --name-only | grep -iE 'provision|\.p12|\.cer|secret|\.env|GoogleService'

# 2. Is a shared scheme present? Without one, CI cannot build.
git diff --cached --name-only | grep xcshareddata/xcschemes
```

If check 1 prints anything, unstage it. If check 2 prints nothing, open Xcode →
Product → Scheme → Manage Schemes → tick **Shared** on the app scheme, then re-stage.

### 2.5 Commit and push

```sh
git commit -m "chore: import pre-pivot DeepMine source"
git push -u origin import/pre-pivot-baseline
```

### 2.6 Tag the pre-pivot state

Backlog M0-03 requires the last working Pomodoro build to stay recoverable. Tag it at the
import commit, before any pivot work lands on top:

```sh
git tag -a v0-pomodoro-baseline -m "Last pre-pivot Pomodoro build"
git push origin v0-pomodoro-baseline
```

This tag is what makes deletion safe later. Anything removed during the pivot can be read
back out of the tag, so the removal work does not need to be cautious or partial.

## 3. What happens next

Once `import/pre-pivot-baseline` is pushed:

1. Fill in `docs/CURRENT_PROJECT_AUDIT.md` from the real source (M0-02). It is currently a
   blank template — every field is a question the code answers.
2. Resolve the open decisions in `docs/PIVOT_PLAN_REVIEW.md` §4. Those decisions are the
   ones that determine how much existing work is reused versus rewritten, and they are all
   blocked on the audit.
3. Revise `TECHNICAL_PLAN.md` §3 (module structure) to match the project's real layout
   rather than the proposed greenfield tree.
4. Add CI (M0-04) against the imported, still-working baseline — a green build on known-good
   code, before the pivot starts changing things.

Step 4 matters in that order. CI added *after* the pivot begins cannot distinguish "the
pivot broke this" from "this was already broken", which is exactly the signal it exists to
provide.

## 4. If the local project turns out not to be worth importing

Possible, and worth naming rather than discovering halfway through: the existing app may be
a thin SwiftUI timer with little reusable surface. If the audit finds that the reusable
portion is small — no meaningful asset library, no persistence layer worth keeping, no
design system — then a clean project is the cheaper path, and the pivot documents should be
re-scoped accordingly.

Import first regardless. That conclusion is only trustworthy once someone has looked at the
real code, and the tag costs nothing to keep.
