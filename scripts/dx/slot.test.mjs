import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const SCRIPT = path.join(path.dirname(fileURLToPath(import.meta.url)), "slot.sh");
const IS_WIN = process.platform === "win32";

// How does this machine's bash open Windows paths? WSL needs /mnt/<drive>/...,
// Git Bash accepts C:/..., native bash uses them as-is. Detect once by trying
// to execute a probe script in each form: the form that runs is the transform.
// Custom env vars do not cross the WSL boundary on some hosts, so everything
// the child bash needs is carried by argv and by wrapper scripts below.
const toBash = (() => {
  if (!IS_WIN) return (p) => p;
  const probeSh = path.join(os.tmpdir(), `mgos-slot-probe-${process.pid}.sh`);
  fs.writeFileSync(probeSh, "echo RAN\n");
  const fwd = (p) => p.replace(/\\/g, "/");
  const wsl = (p) => {
    const f = fwd(p);
    const d = /^([A-Za-z]):[\\/]/.exec(p);
    return d ? `/mnt/${d[1].toLowerCase()}/${f.slice(3)}` : f;
  };
  let form = fwd;
  for (const candidate of [fwd(probeSh), wsl(probeSh), probeSh]) {
    const r = spawnSync("bash", [candidate], { encoding: "utf8" });
    if (r.status === 0 && r.stdout.includes("RAN")) {
      form = candidate === probeSh ? (p) => p : candidate === wsl(probeSh) ? wsl : fwd;
      break;
    }
  }
  fs.unlinkSync(probeSh);
  return form;
})();

// Every git call runs through the same bash git slot.sh uses: a worktree
// created by WSL git records /mnt/... gitdir paths that Windows git cannot
// read, so mixing gits across the worktree boundary fails on "not a git
// repository".
const GITSH = path.join(os.tmpdir(), `mgos-slot-gitsh-${process.pid}.sh`);
fs.writeFileSync(GITSH, 'exec git "$@"\n');

function git(cwd, ...args) {
  const result = spawnSync("bash", [toBash(GITSH), "-C", toBash(cwd), ...args], { encoding: "utf8" });
  assert.equal(result.status, 0, `git ${args.join(" ")} failed: ${result.stderr}`);
  return result.stdout.trim();
}

/** Temp repo with one commit on `main`, mirroring the real slot host. */
function fixture() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "mgos-slot-test-"));
  const repo = path.join(root, "repo");
  const home = path.join(root, "dxhome");
  fs.mkdirSync(repo, { recursive: true });
  fs.mkdirSync(home, { recursive: true });
  git(repo, "init", "-q", "-b", "main");
  git(repo, "config", "user.email", "slot-test@example.invalid");
  git(repo, "config", "user.name", "slot test");
  fs.writeFileSync(path.join(repo, "file.txt"), "committed\n");
  git(repo, "add", "file.txt");
  git(repo, "commit", "-qm", "base");
  git(repo, "branch", "origin/main");
  // The wrapper exports MGOS_DX_HOME inside bash and forwards argv: env vars
  // do not survive the WSL interop boundary, script arguments always do.
  const wrapper = path.join(root, "invoke.sh");
  fs.writeFileSync(wrapper, `export MGOS_DX_HOME='${toBash(home)}'\nexec bash '${toBash(SCRIPT)}' "$@"\n`);
  return { root, repo, home, wrapper: toBash(wrapper) };
}

function run(f, ...args) {
  return spawnSync("bash", [f.wrapper, ...args], { cwd: f.repo, encoding: "utf8" });
}

/** Slot paths in both forms: `win` for node fs, `bash` for what slot.sh prints. */
function slotPaths(f, name) {
  return {
    win: path.join(f.home, "worktrees", name),
    bash: `${toBash(f.home)}/worktrees/${name}`,
  };
}

test("a claim creates an isolated worktree on its own branch without touching the shared checkout", () => {
  const f = fixture();
  const claim = run(f, "claim", "alpha", "--owner", "agent-a");
  assert.equal(claim.status, 0, claim.stderr);
  const slot = slotPaths(f, "alpha");
  assert.equal(claim.stdout.trim(), slot.bash);
  assert.equal(git(slot.win, "symbolic-ref", "--short", "HEAD"), "task/alpha");
  // The shared checkout keeps its branch and its clean tree.
  assert.equal(git(f.repo, "symbolic-ref", "--short", "HEAD"), "main");
  assert.equal(git(f.repo, "status", "--porcelain"), "");
});

test("two agents on different slots never share a working tree or lose edits", () => {
  const f = fixture();
  assert.equal(run(f, "claim", "alpha").status, 0);
  assert.equal(run(f, "claim", "beta").status, 0);
  const a = slotPaths(f, "alpha");
  const b = slotPaths(f, "beta");
  assert.notEqual(a.win, b.win);
  fs.writeFileSync(path.join(a.win, "only-alpha.txt"), "alpha work\n");
  assert.equal(fs.existsSync(path.join(b.win, "only-alpha.txt")), false);
  assert.equal(git(a.win, "status", "--porcelain"), "?? only-alpha.txt");
  assert.equal(git(b.win, "status", "--porcelain"), "");
  assert.equal(git(f.repo, "status", "--porcelain"), "");
  // Neither slot flipped the other's branch.
  assert.equal(git(a.win, "symbolic-ref", "--short", "HEAD"), "task/alpha");
  assert.equal(git(b.win, "symbolic-ref", "--short", "HEAD"), "task/beta");
});

test("a second claim of the same slot name is refused instead of reusing a live checkout", () => {
  const f = fixture();
  assert.equal(run(f, "claim", "alpha").status, 0);
  const again = run(f, "claim", "alpha");
  assert.notEqual(again.status, 0);
  assert.match(again.stderr, /already claimed/);
});

test("claim refuses a branch that already exists so committed work is never reset", () => {
  const f = fixture();
  git(f.repo, "branch", "task/alpha", "main");
  const claim = run(f, "claim", "alpha");
  assert.notEqual(claim.status, 0);
  assert.match(claim.stderr, /branch 'task\/alpha' already exists/);
});

test("claim rejects an unknown ref rather than creating a slot in an undefined state", () => {
  const f = fixture();
  const claim = run(f, "claim", "alpha", "--ref", "origin/does-not-exist");
  assert.notEqual(claim.status, 0);
  assert.match(claim.stderr, /not found/);
});

test("release protects uncommitted work and only discards it on explicit --force", () => {
  const f = fixture();
  assert.equal(run(f, "claim", "alpha").status, 0);
  const slot = slotPaths(f, "alpha");
  fs.writeFileSync(path.join(slot.win, "wip.txt"), "unpushed\n");
  const refused = run(f, "release", "alpha");
  assert.notEqual(refused.status, 0);
  assert.match(refused.stderr, /uncommitted changes/);
  assert.ok(fs.existsSync(path.join(slot.win, "wip.txt")));
  const forced = run(f, "release", "alpha", "--force");
  assert.equal(forced.status, 0, forced.stderr);
  assert.equal(fs.existsSync(slot.win), false);
  // The branch survives the slot so committed work can still be merged.
  assert.equal(git(f.repo, "rev-parse", "--verify", "task/alpha").length, 40);
});

test("release keeps a clean slot's branch and list reports only slot worktrees", () => {
  const f = fixture();
  assert.equal(run(f, "claim", "alpha").status, 0);
  const slot = slotPaths(f, "alpha");
  fs.writeFileSync(path.join(slot.win, "done.txt"), "work\n");
  git(slot.win, "add", "done.txt");
  git(slot.win, "commit", "-qm", "alpha work");
  const head = git(slot.win, "rev-parse", "HEAD");
  const listed = run(f, "list");
  assert.equal(listed.status, 0, listed.stderr);
  assert.match(listed.stdout, /alpha\s+task\/alpha/);
  assert.doesNotMatch(listed.stdout, new RegExp(toBash(f.repo).replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "$", "m"));
  assert.equal(run(f, "release", "alpha").status, 0);
  assert.equal(git(f.repo, "rev-parse", "task/alpha"), head);
});

test("status names the shared checkout as off-limits for branch switching", () => {
  const f = fixture();
  const shared = run(f, "status");
  assert.equal(shared.status, 0, shared.stderr);
  assert.match(shared.stdout, /shared checkout/);
  const slot = slotPaths(f, "alpha");
  assert.equal(run(f, "claim", "alpha").status, 0);
  const inSlot = spawnSync("bash", [f.wrapper, "status"], { cwd: slot.win, encoding: "utf8" });
  assert.equal(inSlot.status, 0, inSlot.stderr);
  assert.match(inSlot.stdout, /slot:\s+alpha/);
});

test("a slot name that would break a path or branch is refused", () => {
  const f = fixture();
  for (const bad of ["../escape", "Alpha", "a", "name with space"]) {
    const claim = run(f, "claim", bad);
    assert.notEqual(claim.status, 0, `expected refusal for ${bad}`);
  }
});
