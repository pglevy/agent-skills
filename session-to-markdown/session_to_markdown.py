#!/usr/bin/env python3
"""Convert a Kiro session export (folder with messages.jsonl + session.json) to readable markdown.

usage: session_to_markdown.py <session-dir | messages.jsonl> [out.md] [--max-tool-chars N]
                              [--no-tools] [--thinking]
defaults: out = <session-dir-name>.md next to the input; tool output clipped to 1500 chars.
Reasoning blocks are redacted ("...") in Kiro exports, so they are skipped unless --thinking.
"""
import argparse, json, sys
from pathlib import Path


def clip(s, n):
    s = s if isinstance(s, str) else json.dumps(s, indent=2, ensure_ascii=False)
    return s if len(s) <= n else s[:n] + f"\n… [{len(s) - n} more chars truncated]"


def fence(text, lang=""):
    ticks = "```"
    while ticks in text:
        ticks += "`"
    return f"{ticks}{lang}\n{text}\n{ticks}\n"


def convert(src, max_tool, tools, thinking):
    src = Path(src).expanduser()
    msgs = src / "messages.jsonl" if src.is_dir() else src
    meta = {}
    try:
        meta = json.load(open(msgs.parent / "session.json"))
    except Exception:
        pass
    out = [f"# {meta.get('title') or msgs.parent.name}\n"]
    info = [("Session", meta.get("id")), ("Created", meta.get("createdAt")),
            ("Last modified", meta.get("lastModifiedAt")),
            ("Workspace", ", ".join(meta.get("workspacePaths", [])) or None)]
    out += [f"- **{k}:** {v}" for k, v in info if v]
    out.append("")

    calls, buf = {}, None  # buf = (operationType, [chunks])

    def flush():
        nonlocal buf
        if buf:
            kind, chunks = buf
            text = "".join(chunks).strip()
            if kind == "Reasoning":
                if thinking and text.strip("."):
                    out.append("<details><summary>Thinking</summary>\n\n" + text + "\n\n</details>\n")
            elif text:
                out.append("### Assistant\n\n" + text + "\n")
        buf = None

    for line in open(msgs, encoding="utf-8"):
        try:
            m = json.loads(line)
            p = m["payload"]
        except Exception:
            continue
        t = p.get("type")
        if t == "assistant":
            kind = p.get("operationType", "Say")
            if buf and buf[0] == kind:
                buf[1].append(p.get("content", ""))
            else:
                flush()
                buf = (kind, [p.get("content", "")])
            continue
        flush()
        if t == "user":
            out.append(f"---\n\n## User\n\n*{m.get('timestamp', '')}*\n\n{p.get('content', '')}\n")
        elif t == "steering_inclusion":
            docs = [d.replace("file://", "") for d in p.get("documents", [])]
            if docs:
                out.append("*Steering included:* " + ", ".join(f"`{d}`" for d in docs) + "\n")
        elif t == "tool_call" and tools:
            args = p.get("args") or {}
            expl = args.get("explanation") if isinstance(args, dict) else None
            body = "<details><summary>🔧 <code>%s</code>%s</summary>\n\n" % (
                p.get("toolName"), f" — {expl}" if expl else "")
            body += fence(clip({k: v for k, v in args.items() if k != "explanation"}
                               if isinstance(args, dict) else args, max_tool), "json")
            out.append(body)  # closed when result arrives
            calls[p.get("toolCallId")] = True
        elif t == "tool_result" and tools:
            ok = "" if p.get("success", True) else " (failed)"
            res = fence(clip(p.get("content", ""), max_tool))
            if calls.pop(p.get("toolCallId"), None):
                out.append(f"**Result{ok}:**\n\n{res}\n</details>\n")
            else:
                out.append(f"<details><summary>Tool result{ok}</summary>\n\n{res}\n</details>\n")
    flush()
    # close any tool_call without a result
    text = "\n".join(out)
    if text.count("<details>") > text.count("</details>"):
        text += "\n</details>\n" * (text.count("<details>") - text.count("</details>"))
    return text


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("session")
    ap.add_argument("out", nargs="?")
    ap.add_argument("--max-tool-chars", type=int, default=1500)
    ap.add_argument("--no-tools", action="store_true", help="omit tool calls/results")
    ap.add_argument("--thinking", action="store_true", help="include reasoning blocks")
    a = ap.parse_args()
    src = Path(a.session).expanduser()
    if not src.exists():
        sys.exit(f"not found: {src}")
    dest = Path(a.out).expanduser() if a.out else (
        (src.parent if src.is_file() and src.name == "messages.jsonl" else src).with_suffix(".md")
        if src.is_dir() else src.with_suffix(".md"))
    if src.is_file() and src.name == "messages.jsonl" and not a.out:
        dest = src.parent.with_suffix(".md")
    dest.write_text(convert(src, a.max_tool_chars, not a.no_tools, a.thinking), encoding="utf-8")
    print(f"wrote {dest}")


main()
