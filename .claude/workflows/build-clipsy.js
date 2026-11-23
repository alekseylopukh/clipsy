export const meta = {
  name: 'build-clipsy',
  description: 'Build docs/roadmap.md in parallel: independent tasks run in their own worktrees, each reviewed until PASS, then integrated one by one with a full build and test; one PR at the end',
  whenToUse: 'The maintainer asks to build Clipsy (or a range of roadmap tasks) autonomously.',
  phases: [
    { title: 'Plan', detail: 'prepare the branch and list pending roadmap tasks with their dependencies' },
    { title: 'Build', detail: 'per ready task, in its own worktree: implement, review until PASS, gated commit' },
    { title: 'Integrate', detail: 'one at a time: cherry-pick onto the branch, build, test, lint, review any conflict fix' },
    { title: 'Ship', detail: 'push the branch and open or refresh one PR' },
  ],
}

// args (all optional): { from, to, branch: 'build/roadmap', maxTasks: 1000, maxReviewRounds: 3, concurrency: 4, openPR: true,
//   prebuilt: { T1.2: '<reviewed commit sha>' }, resume: { T1.2: '<worktree with the staged task>' }, resumeNotes: { T1.2: '...' },
//   extraTasks: [{ id, title, deps, prompt, goal }] }
const opts = Object.assign(
  { from: null, to: null, branch: 'build/roadmap', maxTasks: 1000, maxReviewRounds: 3, concurrency: 4, openPR: true, prebuilt: {}, resume: {}, extraTasks: [] },
  args || {},
)

if (!opts.branch || /^(main|master)$/.test(opts.branch)) {
  return { stopped: 'plan', problem: `branch "${opts.branch}" is not allowed; the workflow never works on main` }
}

const MAIN = `the main checkout (the Clipsy git repository in the current working directory; \`git rev-parse --show-toplevel\` from there)`

const DECISIONS = `Maintainer decisions (updated 2026-11-23, after the v0.1.0 release). Record each one in the doc it belongs to the first time a task depends on it:
- v0.1.0 is released and people run it. Never edit an existing migration in Store/AppDatabase.swift; any schema change is a new registered migration (v2_…, v3_…) with a test that migrates a v1 database. Keep \`card.content_hash\` UNIQUE: capture dedupe relies on it.
- Duplicate is not in v1 (roadmap "Needs the maintainer" → Decided); do not build it.
- The maintainer uses the released Clipsy daily on this Mac, and until T14.8 lands the Debug build shares its bundle id, database, UserDefaults and hotkeys. Never launch Clipsy.app, never open or write ~/Library/Application Support/Clipsy or the app.gonar.clipsy defaults domain, and never run tccutil. Tests use temporary directories and private pasteboards only.
- Releases are live: the release secrets are set and .github/workflows/release.yml publishes on vX.Y.Z tags. Never tag, release, or change the signing, notarization or Sparkle key wiring unless the task says so. CI builds on the xcode-27 runner with Xcode 27.2.
- URL scheme: "clipsy", grammar in docs/product.md §3.7.
- Linking: the app links only the ClipsyKit product. Re-export what the app needs from ClipsyKit (\`@_exported import\`). A minimal project.pbxproj edit is allowed only to change a build setting; verify it with scripts/build.sh.
- Payload GC (Store.PayloadStore.collectGarbage) must never race with capture: a file written by store() before its row is inserted must survive GC.
- Tests and debug code never touch NSPasteboard.general: inject the pasteboard and use a uniquely named private NSPasteboard in tests. The maintainer's real clipboard must never be read or changed.
- Any other product question: choose what a first-party macOS app would do, follow docs/ and Apple's Human Interface Guidelines, record the choice as a working default in docs/roadmap.md, and carry on. Never block on a question you can answer yourself.`

const APPLE = `Use Apple's documentation when you are unsure about an API: the guides in /Applications/Xcode.app/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation/, the SDK headers and swiftinterface files under \`xcrun --show-sdk-path\`, and developer.apple.com (WebFetch). Prefer the newest macOS 26 APIs.`

const GH = `Use the GitHub CLI as the account that owns the origin repository: read the owner from \`git remote get-url origin\`, and if \`gh auth status\` lists several accounts run gh with \`GH_TOKEN=$(gh auth token -u <owner>)\`.`

const inWt = (wt) => `You work ONLY in the git worktree ${wt}. Start every shell command with \`cd ${wt} && \` and use absolute paths under ${wt} for every file you read or edit. Never touch ${MAIN}: other agents work in parallel and it belongs to the integrator. Follow CLAUDE.md and .claude/rules/code-rules.md exactly.`

const PLAN = {
  type: 'object',
  properties: {
    ok: { type: 'boolean' },
    problem: { type: 'string' },
    root: { type: 'string' },
    undone: { type: 'array', items: { type: 'string' } },
    head: { type: 'string' },
    tasks: {
      type: 'array',
      items: {
        type: 'object',
        properties: { id: { type: 'string' }, title: { type: 'string' }, deps: { type: 'array', items: { type: 'string' } } },
        required: ['id', 'title', 'deps'],
      },
    },
  },
  required: ['ok', 'tasks', 'root', 'head', 'undone'],
}

const WORK = {
  type: 'object',
  properties: {
    status: { type: 'string', enum: ['staged', 'blocked'] },
    summary: { type: 'string' },
    blockedReason: { type: 'string' },
    commitTitle: { type: 'string' },
    checks: { type: 'string' },
    humanChecks: { type: 'array', items: { type: 'string' } },
  },
  required: ['status', 'summary'],
}

const VERDICT = {
  type: 'object',
  properties: { verdict: { type: 'string', enum: ['PASS', 'FAIL'] }, tree: { type: 'string' }, report: { type: 'string' } },
  required: ['verdict', 'tree', 'report'],
}

const OK = {
  type: 'object',
  properties: { ok: { type: 'boolean' }, sha: { type: 'string' }, problem: { type: 'string' } },
  required: ['ok'],
}

const INTEGRATE = {
  type: 'object',
  properties: {
    status: { type: 'string', enum: ['committed', 'staged', 'failed'] },
    kind: { type: 'string', enum: ['conflict', 'fix'] },
    sha: { type: 'string' },
    summary: { type: 'string' },
    checks: { type: 'string' },
  },
  required: ['status', 'summary'],
}

phase('Plan')
const plan = await agent(
  `In ${MAIN}: prepare the branch and list the work. Change no tracked files.
1. If \`git status --porcelain\` is not empty, stop: ok=false, problem = the list. Never stash or discard anything.
2. Run \`git fetch origin\`, \`git worktree prune\` and \`git for-each-ref --format='%(refname)' refs/clipsy/integrating/ | while read -r ref; do git update-ref -d "$ref"; done\` (drops markers left by an interrupted run).
3. Branch "${opts.branch}":
   - if it does not exist locally, run \`git switch -c ${opts.branch} origin/main\`;
   - if \`git log origin/main..${opts.branch}\` is empty, run \`git switch -C ${opts.branch} origin/main\`;
   - if \`git merge-base --is-ancestor origin/main ${opts.branch}\` succeeds, run \`git switch ${opts.branch}\`;
   - otherwise it counts as squash-merged only if every commit in \`git log origin/main..${opts.branch}\` has a "Roadmap: T…" line and every one of those tasks has "- Status: done" in \`git show origin/main:docs/roadmap.md\`; then run \`git switch -C ${opts.branch} origin/main\`. Otherwise stop: ok=false, problem = "branch ${opts.branch} has unmerged work on an outdated base".
4. Read docs/roadmap.md on that branch. Every task is a heading "### T<m>.<n> <title>" with a "- Depends on:" field. A task is done when its section has "- Status: done" or its milestone heading ends with "done".
5. Return root = the absolute path of the checkout, head = \`git rev-parse HEAD\`, undone = the ids of every task that is not done (whole roadmap, ignoring any range), and the tasks that are not done in roadmap order${opts.from ? `, starting at ${opts.from}` : ''}${opts.to ? `, ending at ${opts.to} inclusive` : ''}. For each task, deps = the task ids from its "Depends on" field that are not done (ignore anything that is not a T<m>.<n> id).`,
  { label: 'plan', phase: 'Plan', schema: PLAN },
)

if (!plan || !plan.ok) {
  return { stopped: 'plan', problem: plan ? plan.problem : 'planner failed' }
}

const tasks = [...plan.tasks.slice(0, opts.maxTasks), ...opts.extraTasks].map((t) => ({ ...t, deps: t.deps || [] }))
if (plan.tasks.length > tasks.length) log(`maxTasks=${opts.maxTasks}: ${plan.tasks.length - tasks.length} pending tasks left for a later run`)
const pendingIds = new Set(tasks.map((t) => t.id))
const outOfRun = new Set([...plan.tasks.slice(opts.maxTasks).map((t) => t.id), ...(plan.undone || []).filter((id) => !pendingIds.has(id))])
const wtRoot = `${plan.root.replace(/\/$/, '')}-worktrees`
let head = plan.head
log(`${tasks.length} pending tasks on ${opts.branch}, up to ${opts.concurrency} at a time; worktrees in ${wtRoot}`)

const passed = (v) => v && v.verdict === 'PASS' && /^VERDICT:\s*PASS\b/m.test(v.report || '')

const review = (task, dir, goal, checks, round) =>
  agent(
    `Review the staged change in the git worktree ${dir}: run \`git -C ${dir} diff --cached\` and read files under ${dir} (read-only).
Goal: ${goal}
Checks the author reports: ${checks || 'not reported'}.
Return the verdict, \`git -C ${dir} write-tree\` output as tree, and the full report in the code-rules.md format (it starts with "VERDICT:").`,
    { label: `review ${task.id} #${round}`, phase: task.phaseName, agentType: 'swift-reviewer', schema: VERDICT },
  )

// review → fix loop on whatever is staged in `dir`; returns { verdict, work } or { stop }
async function reviewLoop(task, dir, goal, work, fixContext) {
  let verdict = null
  for (let round = 1; round <= opts.maxReviewRounds; round++) {
    verdict = await review(task, dir, goal, work.checks, round)
    if (!verdict) verdict = await review(task, dir, goal, work.checks, `${round}b`)
    if (passed(verdict) || round === opts.maxReviewRounds || !verdict) break
    const fixed = await agent(
      `${fixContext}

The independent review failed. Fix every blocking finding below, re-run \`scripts/build.sh\`, \`scripts/build.sh test\` and \`scripts/lint.sh\`, and restage exactly the change's files with no leftovers. Run swiftformat on the staged .swift files, restage, and make \`scripts/lint.sh --staged\` pass (the git pre-commit hook runs it). Do not commit. If a finding is wrong, leave the code and explain why in the summary.
Return humanChecks only for checks that are new.

Review report:
${verdict.report}`,
      { label: `fix ${task.id} #${round}`, phase: task.phaseName, schema: WORK },
    )
    if (!fixed || fixed.status === 'blocked') return { stop: fixed ? fixed.blockedReason || fixed.summary : 'fixer failed' }
    work = Object.assign({}, work, fixed, {
      humanChecks: [...new Set([...(work.humanChecks || []), ...(fixed.humanChecks || [])])],
    })
  }
  if (!passed(verdict)) return { stop: 'review did not pass', report: verdict ? verdict.report : 'no review' }
  return { verdict, work }
}

const commitIn = (task, dir, tree, message, label) =>
  agent(
    `In the git worktree ${dir}, a staged change passed review on tree ${tree}. Do exactly this:
1. Run \`git -C ${dir} write-tree\`. If it is not ${tree}, stop: ok=false, problem="staged tree changed after review". If \`git -C ${dir} status --porcelain\` lists anything besides staged changes, stop: ok=false, problem="leftovers" plus the list. Do not touch the index.
2. Run \`cd ${dir} && .claude/skills/pre-commit-review/scripts/approve.sh\`.
3. Commit with a quoted heredoc so nothing is expanded, exactly:
git -C ${dir} commit -F - <<'CLIPSY_MSG'
${message}
CLIPSY_MSG
4. Return ok and the new commit sha. If the commit gate or the git hook blocks the commit, return ok=false with its output.`,
    { label, phase: task.phaseName, effort: 'low', schema: OK },
  )

const messageFor = (title, task, humanChecks) =>
  [
    title,
    '',
    `Roadmap: ${task.id}`,
    ...(humanChecks || []).map((c) => `Human check: ${c.replace(/\n/g, ' ')}`),
    '',
    'Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>',
  ].join('\n')

// build one task in its own worktree; returns { sha } or { skip } or { fail }
async function resumeTask(task, wt) {
  task.phaseName = 'Build'
  const goal = task.goal || `roadmap task ${task.id} "${task.title}" in docs/roadmap.md. Check its Deliverable and Acceptance as well as the rules. The change must also add "- Status: done" to that task's section. Earlier reviews of this change failed; judge the current staged state on its merits.`
  const work = await agent(
    `${inWt(wt)}\n\nRoadmap task ${task.id} ("${task.title}") is staged in the worktree, but its last independent review failed. First bring the worktree up to date: commit nothing, but rebase the staged work onto ${head} without the shared stash stack, in ONE shell command so the sha is saved before the reset: \`sha=$(git -C ${wt} stash create) && test -n "$sha" && git -C ${wt} update-ref refs/clipsy/resume/${task.id} "$sha" && git -C ${wt} reset --hard ${head}\` (if it stops because sha is empty, nothing is staged: stop and return blocked). Then \`git -C ${wt} stash apply --index refs/clipsy/resume/${task.id}\`; if it refuses because of index conflicts, run it without --index. Resolve conflicts keeping both intents, restage, and only then \`git -C ${wt} update-ref -d refs/clipsy/resume/${task.id}\`. Then run \`git -C ${wt} diff --cached\` and make the change correct and simple: ${(opts.resumeNotes || {})[task.id] || ''} Prefer the simplest design that meets the Acceptance; remove complexity the earlier fix rounds added if it is not needed. Verify with scripts/build.sh, scripts/build.sh test, scripts/lint.sh --staged. Leave everything staged, no leftovers, do not commit.\nReturn status "staged", summary, commitTitle, checks, humanChecks.`,
    { label: `resume ${task.id}`, phase: 'Build', schema: WORK },
  )
  if (!work || work.status === 'blocked') return { fail: work ? work.blockedReason || work.summary : 'resume failed', wt }
  const r = await reviewLoop(task, wt, goal, work, `${inWt(wt)}\nRoadmap task ${task.id} ("${task.title}") is staged in the worktree.`)
  if (r.stop) return { fail: r.stop, report: r.report, wt }
  const commit = await commitIn(task, wt, r.verdict.tree, messageFor(r.work.commitTitle || `feat: ${task.title}`, task, r.work.humanChecks), `commit ${task.id}`)
  if (!commit || !commit.ok) return { fail: `commit failed: ${commit ? commit.problem : 'agent failed'}`, wt }
  return { sha: commit.sha, wt, title: r.work.commitTitle, humanChecks: r.work.humanChecks || [] }
}

async function buildTask(task, base) {
  task.phaseName = 'Build'
  const wt = `${wtRoot}/${task.id}`
  const setup = await agent(
    `In ${MAIN}, create a worktree for task ${task.id}. Run exactly:
mkdir -p ${wtRoot} && git worktree add -B task/${task.id} ${wt} ${base}
If ${wt} already exists, first run \`git worktree remove --force ${wt}\` and then the command above.
Then warm the build caches with copy-on-write clones (instant on APFS), ignoring errors: \`cp -cR "$(git rev-parse --show-toplevel)/.build" ${wt}/.build 2>/dev/null; cp -cR "$(git rev-parse --show-toplevel)/Packages/ClipsyKit/.build" ${wt}/Packages/ClipsyKit/.build 2>/dev/null; true\`. Return ok=true and sha=\`git -C ${wt} rev-parse HEAD\`, or ok=false with the error.`,
    { label: `worktree ${task.id}`, phase: 'Build', effort: 'low', schema: OK },
  )
  if (!setup || !setup.ok) return { fail: `worktree setup failed: ${setup ? setup.problem : 'agent failed'}` }

  const goal = task.goal || `roadmap task ${task.id} "${task.title}" in docs/roadmap.md. Check its Deliverable and Acceptance as well as the rules. The change must also add "- Status: done" to that task's section.`
  const work = task.prompt ? await agent(`${inWt(wt)}\n\n${task.prompt}\n\n- ${DECISIONS}\n- ${APPLE}\n- Verify from ${wt}: \`scripts/build.sh\`, \`scripts/build.sh test\`, \`scripts/lint.sh\`. Stage exactly the change's files with \`git -C ${wt} add <paths>\`, run swiftformat on staged .swift files, restage, and make \`scripts/lint.sh --staged\` pass. Leave no leftovers. Do NOT commit.\nReturn: status "staged", a summary, a Conventional Commit title, the checks you ran, and humanChecks for what only a person can verify in the running app.`, { label: `implement ${task.id}`, phase: 'Build', schema: WORK }) : await agent(
    `${inWt(wt)}

Implement roadmap task ${task.id} ("${task.title}").
- Read the task in ${wt}/docs/roadmap.md and every doc section its "Spec" field links. The docs win over the roadmap.
- ${DECISIONS}
- ${APPLE}
- Return status "blocked" only when nothing in the task can be done without the maintainer's personal account, hardware or money. Then leave the worktree unchanged and give the reason.
- You may improve the roadmap while you work: if the task's plan is wrong or a missing piece blocks quality, fix the plan in docs/roadmap.md as part of this change and say so in the summary. Keep edits to shared files (Package.swift, Localizable.xcstrings, docs) small and local: other tasks change them in parallel.
- Load the skills the work needs: macos-native-ui for any UI, swift-concurrency for isolation work, swift-testing-pro for tests, swiftui-expert-skill or swiftui-pro for SwiftUI.
- Implement the Deliverable. Meet every Acceptance point and the "Rules for every task" in the roadmap.
- In docs/roadmap.md, add the line "- Status: done" as the last field of this task's section.
- Verify from ${wt}: \`scripts/build.sh\`, \`scripts/build.sh test\`, \`scripts/lint.sh\`. Fix until all pass. Never launch Clipsy.app or any window: the maintainer is working on this Mac and nothing may appear on screen. Never call APIs that show system permission prompts (Accessibility, Input Monitoring) from tests. For UI work, check the look offscreen instead: render the views to PNG files (ImageRenderer, or NSHostingView with bitmapImageRepForCachingDisplay) from a test or a temporary script in light and dark appearance, look at the PNGs, and delete temporary files afterwards.
- Stage exactly this task's files with \`git -C ${wt} add <paths>\`. Then run \`cd ${wt} && swiftformat <the staged .swift files>\`, restage them, and run \`cd ${wt} && scripts/lint.sh --staged\`; the git pre-commit hook runs exactly this, so it must pass. Leave no unstaged or untracked leftovers. Do NOT commit and do NOT run approve.sh.
Return: status "staged", a summary, a Conventional Commit title, the checks you ran with results, and the task's "Human check" items (if any) as humanChecks.`,
    { label: `implement ${task.id}`, phase: 'Build', schema: WORK },
  )
  if (!work) return { fail: 'implementer failed', wt }
  if (work.status === 'blocked') return { skip: work.blockedReason || work.summary, wt }

  const r = await reviewLoop(task, wt, goal, work, `${inWt(wt)}\nRoadmap task ${task.id} ("${task.title}") is staged in the worktree.`)
  if (r.stop) return { fail: r.stop, report: r.report, wt }

  const commit = await commitIn(task, wt, r.verdict.tree, messageFor(r.work.commitTitle || `feat: ${task.title}`, task, r.work.humanChecks), `commit ${task.id}`)
  if (!commit || !commit.ok) return { fail: `commit failed: ${commit ? commit.problem : 'agent failed'}`, wt }
  return { sha: commit.sha, wt, title: r.work.commitTitle, humanChecks: r.work.humanChecks || [] }
}

// one integration at a time on the branch in the main checkout
let lock = Promise.resolve()
const serial = (fn) => {
  const p = lock.then(fn)
  lock = p.catch(() => {})
  return p
}

async function integrate(task, built) {
  task.phaseName = 'Integrate'
  const before = head
  // owned=true: the integrator returned "staged", so the index holds only this workflow's work
  const restore = async (fail, owned = false) => {
    const undone = await agent(
      `In ${MAIN}, on branch ${opts.branch}, the integration of ${task.id} failed and must be undone so later tasks can integrate. ${
        owned
          ? ''
          : `First check: if \`git rev-parse -q --verify refs/clipsy/integrating/${task.id}\` fails, the integration stopped in step 1 before it changed anything (any modified files belong to someone else), so leave the checkout exactly as it is and return ok. Otherwise: `
      }if a cherry-pick is in progress run \`git cherry-pick --abort\`, then run \`git reset --hard ${before}\` and confirm \`git status --porcelain --untracked-files=no\` is empty, then run \`git update-ref -d refs/clipsy/integrating/${task.id}\`. Do not touch any other branch or worktree. Return ok.`,
      { label: `restore ${task.id}`, phase: 'Integrate', effort: 'low', schema: OK },
    )
    if (!undone || !undone.ok) {
      log(`restore after ${task.id} failed`)
      return { ...fail, fail: `${fail.fail}; restoring the branch also failed` }
    }
    return fail
  }
  const res = await agent(
    `In ${MAIN}, on branch ${opts.branch}, integrate roadmap task ${task.id} ("${task.title}"), commit ${built.sha} from branch task/${task.id}.
1. Run \`git update-ref -d refs/clipsy/integrating/${task.id}\` (ignore an error if it does not exist). Check \`git branch --show-current\` is ${opts.branch}; otherwise return status "failed" and change nothing. If \`git status --porcelain\` shows only untracked files (lines starting with "??"), they are strays that a parallel agent wrote here by mistake: move them into ${wtRoot}/_strays/ (mkdir -p) and mention them in the summary. If tracked files are modified, return status "failed" with the details. Otherwise mark the integration as started with \`git update-ref refs/clipsy/integrating/${task.id} HEAD\`.
2. Run \`git cherry-pick ${built.sha}\`.
   - If it applies cleanly, run \`scripts/build.sh\`, \`scripts/build.sh test\` and \`scripts/lint.sh\`. If all pass, return status "committed" and sha = \`git rev-parse HEAD\`. If any fail, fix the cause in the smallest way (the failure comes from combining this task with work integrated before it), stage the fix with \`git add\`, and return status "staged" with kind "fix".
   - If it conflicts, resolve every conflict so both sides keep their intent (other tasks were integrated first), run \`git cherry-pick --quit\` (keeps the resolved index), make sure the build, tests and \`scripts/lint.sh --staged\` pass, stage everything with \`git add\`, and return status "staged" with kind "conflict".
3. Return status "failed" only from step 1. Once you have run the cherry-pick, finish with "committed" or "staged". Never run git commit, never reset, stash or discard other work. Leave no unstaged or untracked leftovers when you return "staged".
Return the checks you ran with results and a summary.`,
    { label: `integrate ${task.id}`, phase: 'Integrate', schema: INTEGRATE },
  )
  if (res && res.status === 'committed' && !res.sha) return restore({ fail: 'integrator returned no sha' }, true)
  if (!res || res.status === 'failed') return restore({ fail: `integration failed: ${res ? res.summary : 'agent failed'}` })
  if (res.status === 'staged') {
    const goal = `integration of roadmap task ${task.id} "${task.title}" onto ${opts.branch}: either the whole task after a conflict resolution, or a fix on top of it. The task commit ${built.sha} on branch task/${task.id} was already reviewed; check that the staged change keeps its intent and that the resolution or fix is correct.`
    const r = await reviewLoop(task, plan.root, goal, { checks: res.checks }, `In ${MAIN}, on branch ${opts.branch}, the integration of roadmap task ${task.id} ("${task.title}") is staged. Work only there.`)
    if (r.stop) return restore({ fail: `integration review: ${r.stop}`, report: r.report }, true)
    const message = res.kind === 'conflict'
      ? messageFor(built.title || `feat: ${task.title}`, task, built.humanChecks)
      : messageFor(`fix: integrate ${task.id}`, task, [])
    const c = await commitIn(task, plan.root, r.verdict.tree, message, `commit integration ${task.id}`)
    if (!c || !c.ok) return restore({ fail: `integration commit failed: ${c ? c.problem : 'agent failed'}` }, true)
    res.sha = c.sha
  }
  const cleaned = await agent(
    `In ${MAIN}, clean up the finished integration: run \`git update-ref -d refs/clipsy/integrating/${task.id}\`, \`git worktree remove --force ${built.wt}\` and \`git branch -D task/${task.id}\`. Then back up the branch: \`git push -q origin ${opts.branch}\` (${GH} if the push needs credentials; never force-push). Return ok.`,
    { label: `cleanup ${task.id}`, phase: 'Integrate', effort: 'low', schema: OK },
  )
  if (!cleaned || !cleaned.ok) log(`cleanup or backup push after ${task.id} did not report ok`)
  head = res.sha
  return { sha: res.sha }
}

phase('Build')
const done = []
const skipped = []
const failed = []
const finished = new Set()
const started = new Set()
const running = new Map()

const blockedBy = (t) => t.deps.find((d) => skipped.some((s) => s.id === d) || failed.some((f) => f.id === d) || outOfRun.has(d))
const ready = (t) => !started.has(t.id) && t.deps.every((d) => finished.has(d) || !pendingIds.has(d))

function schedule() {
  let changed = true
  while (changed) {
    changed = false
    for (const t of tasks) {
      if (started.has(t.id)) continue
      const b = blockedBy(t)
      if (b) {
        started.add(t.id)
        skipped.push({ id: t.id, task: `${t.id} ${t.title}`, reason: `depends on ${b}, which was not finished` })
        log(`skipped ${t.id}: depends on ${b}`)
        changed = true
      }
    }
  }
  for (const t of tasks) {
    if (running.size >= opts.concurrency) break
    if (!ready(t)) continue
    started.add(t.id)
    const base = head
    const p = (async () => {
      const built = opts.prebuilt[t.id]
        ? { sha: opts.prebuilt[t.id], wt: `${wtRoot}/${t.id}`, humanChecks: [] }
        : opts.resume[t.id]
          ? await resumeTask(t, opts.resume[t.id])
          : await buildTask(t, base)
      if (built.skip) {
        skipped.push({ id: t.id, task: `${t.id} ${t.title}`, reason: built.skip })
        log(`skipped ${t.id}: ${built.skip}`)
        return
      }
      if (built.fail) {
        failed.push({ id: t.id, task: `${t.id} ${t.title}`, reason: built.fail, report: built.report, worktree: built.wt })
        log(`failed ${t.id}: ${built.fail}`)
        return
      }
      const integ = await serial(() => integrate(t, built))
      if (integ.fail) {
        failed.push({ id: t.id, task: `${t.id} ${t.title}`, reason: integ.fail, report: integ.report, worktree: built.wt })
        log(`failed ${t.id}: ${integ.fail}`)
        return
      }
      finished.add(t.id)
      done.push({ task: `${t.id} ${t.title}`, sha: integ.sha, humanChecks: built.humanChecks })
      log(`done ${t.id} (${done.length}/${tasks.length})`)
    })()
      .catch((e) => {
        failed.push({ id: t.id, task: `${t.id} ${t.title}`, reason: String(e) })
      })
      .finally(() => {
        running.delete(t.id)
      })
    running.set(t.id, p)
  }
}

schedule()
while (running.size) {
  await Promise.race(running.values())
  schedule()
}
for (const t of tasks) {
  if (!started.has(t.id)) skipped.push({ id: t.id, task: `${t.id} ${t.title}`, reason: 'dependency never ran' })
}

let pr = null
if (opts.openPR && done.length > 0) {
  phase('Ship')
  const esc = (s) => String(s).replace(/"/g, "'").replace(/\n/g, ' ')
  pr = await agent(
    `In ${MAIN}, on branch ${opts.branch}:
1. Push with \`git push -u origin ${opts.branch}\`. Never push main and never force-push.
2. Build the PR description from the whole branch: read \`git log origin/main..HEAD --reverse --format=%B%x00\`. For every commit, take its title, its "Roadmap: T…" line and its "Human check: …" lines.
3. ${GH} If a PR from ${opts.branch} to main is open, replace its title and body; otherwise open one.
Title: "feat: roadmap <first task id>–<last task id>" over all tasks on the branch.
Body, in this order:
- "## Tasks": one line per commit: "- <Roadmap id>: <commit title>".
- "## Status": "${done.length} tasks done in this run; ${skipped.length} skipped; ${failed.length} failed".
- "## Needs the maintainer": ${skipped.length ? skipped.map((s) => `"- ${esc(s.task)}: ${esc(s.reason)}"`).join(', ') : '"nothing"'}.
- "## Failed": ${failed.length ? failed.map((f) => `"- ${esc(f.task)}: ${esc(f.reason)}"`).join(', ') : '"nothing"'}.
- "## Human checks": a task-list checklist "- [ ] <task id>: <check>" for every Human check line. Keep any boxes already ticked in the existing body.
- One "Roadmap: <id>" line per task, so the squash commit records what was done.
- "AI assistance: built by the build-clipsy workflow with Claude Code."
- "🤖 Generated with [Claude Code](https://claude.com/claude-code)"
Return ok and the PR URL in sha.`,
    { label: 'ship', phase: 'Ship', schema: OK },
  )
}

return { branch: opts.branch, done, skipped, failed, pr }
