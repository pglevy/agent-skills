#!/usr/bin/env python3
"""Export Kiro workflow runs (all sessions per step) for one workspace to markdown.

usage: export_kiro_workflows.py [workspace-path] [out-dir] [--max-tool-chars N]
defaults: workspace = current directory, out = <workspace>/gitignore/kiro-workflow-export
Output: <out>/<wf_id>-<name>/INDEX.md + one NN-<node-path>.md per step session.
"""
import json, re, sys, glob, os, argparse
from pathlib import Path

SESS = Path.home() / ".kiro/sessions"

def find_hash_dirs(ws):
    ws = os.path.realpath(ws)
    out = set()
    for f in glob.glob(str(SESS / "*/sess_*/session.json")):
        try:
            d = json.load(open(f))
        except Exception:
            continue
        if any(os.path.realpath(p) == ws for p in d.get("workspacePaths", []) + d.get("rootPaths", [])):
            out.add(Path(f).parent.parent)
    return sorted(out)

def clip(s, n):
    s = s if isinstance(s, str) else json.dumps(s, indent=1)
    return s if len(s) <= n else s[:n] + f"\n… [{len(s)-n} more chars truncated]"

def render_session(path, max_tool):
    lines, buf = [], None  # buf = (kind, [chunks])
    def flush():
        nonlocal buf
        if buf:
            kind, chunks = buf
            text = "".join(chunks).strip()
            if text:
                if kind == "Reasoning":
                    lines.append("<details><summary>Thinking</summary>\n\n" + text + "\n\n</details>\n")
                else:
                    lines.append("**Assistant:**\n\n" + text + "\n")
        buf = None
    for l in open(path):
        try:
            m = json.loads(l); p = m["payload"]
        except Exception:
            continue
        t = p.get("type")
        if t == "assistant":
            kind = p.get("operationType", "Say")
            if buf and buf[0] == kind:
                buf[1].append(p.get("content", ""))
            else:
                flush(); buf = (kind, [p.get("content", "")])
            continue
        flush()
        if t == "user":
            lines.append(f"## User ({m['timestamp']})\n\n{p.get('content','')}\n")
        elif t == "tool_call":
            lines.append(f"**Tool call:** `{p.get('toolName')}`\n```json\n{clip(p.get('args'), max_tool)}\n```\n")
        elif t == "tool_result":
            ok = "" if p.get("success", True) else " (failed)"
            lines.append(f"**Tool result{ok}:**\n```\n{clip(p.get('content',''), max_tool)}\n```\n")
    flush()
    return "\n".join(lines)

def slug(s):
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", s).strip("_")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("workspace", nargs="?", default=os.getcwd()); ap.add_argument("out", nargs="?")
    ap.add_argument("--max-tool-chars", type=int, default=2000)
    a = ap.parse_args()
    out = Path(a.out or Path(a.workspace) / "gitignore" / "kiro-workflow-export").expanduser(); n_wf = n_s = 0
    for h in find_hash_dirs(a.workspace):
        for wf in sorted((h / "workflows").glob("wf_*")):
            sj = wf / "sessions.json"
            if not sj.exists(): continue
            try: state = json.load(open(wf / "workflow-state.json"))
            except Exception: state = {}
            name = state.get("workflowName", "workflow")
            d = out / f"{wf.name}-{slug(name)}"; d.mkdir(parents=True, exist_ok=True)
            idx = [f"# {name} ({wf.name})\n", f"Status: {state.get('status','?')}\n"]
            for i, s in enumerate(json.load(open(sj))["sessions"], 1):
                src = h / s["sessionId"] / "messages.jsonl"
                if not src.exists(): continue
                node = "/".join(s["nodePath"][1:]) or s["nodeId"]
                fn = f"{i:02d}-{slug(node)}.md"
                meta = {}
                try: meta = json.load(open(h / s["sessionId"] / "session.json"))
                except Exception: pass
                head = (f"# {node}\n\n- session: `{s['sessionId']}`\n- source: `{src}`\n"
                        f"- created: {meta.get('createdAt','?')}\n\n")
                (d / fn).write_text(head + render_session(src, a.max_tool_chars))
                idx.append(f"- [{node}]({fn}) — `{s['sessionId']}`"); n_s += 1
            (d / "INDEX.md").write_text("\n".join(idx) + "\n"); n_wf += 1
    print(f"exported {n_wf} workflows, {n_s} sessions -> {out}")

main()
