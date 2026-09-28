#!/usr/bin/env python3
import html
import json
import os
import sys
import time
import urllib.parse
import urllib.request


def env(name: str, default: str = "") -> str:
    return os.getenv(name, default)


def api_call(method: str, payload: dict) -> dict:
    token = env("TG_BOT_TOKEN")
    if not token:
        return {}
    url = f"https://api.telegram.org/bot{token}/{method}"
    data = urllib.parse.urlencode(payload).encode()
    request = urllib.request.Request(url, data=data)
    with urllib.request.urlopen(request, timeout=20) as response:
        return json.loads(response.read().decode())


def elapsed_text(seconds: int) -> str:
    minutes, seconds = divmod(max(0, seconds), 60)
    return f"{minutes}m {seconds}s"


def main() -> int:
    token = env("TG_BOT_TOKEN")
    chat_id = env("TG_CHAT_ID")
    if not token or not chat_id:
        return 0

    percent = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    current_step = int(sys.argv[2]) if len(sys.argv) > 2 else 1
    mode = sys.argv[3] if len(sys.argv) > 3 else "update"
    status = sys.argv[4] if len(sys.argv) > 4 else ""

    start_file = os.path.join(env("RUNNER_TEMP", "/tmp"), "build_start_time")
    try:
        start_time = int(open(start_file, encoding="utf-8").read().strip())
    except (OSError, ValueError):
        start_time = int(time.time())

    elapsed = max(0, int(time.time()) - start_time)
    if 0 < percent < 100:
        padding = 5100 if percent <= 5 else 3600 if percent <= 30 else 2400 if percent <= 60 else 900 if percent <= 85 else 300
        remaining = f"~{elapsed_text(padding)}"
    elif percent >= 100:
        remaining = "0m 0s"
    else:
        remaining = "calculating"

    filled = max(0, min(20, 20 * percent // 100))
    bar = "█" * filled + "░" * (20 - filled)

    steps = [
        "Preparing runner",
        "Syncing sources",
        "Cloning device tree",
        "Configuring build environment",
        "Compiling recovery",
        "Packaging artifacts",
        "Publishing outputs",
    ]
    step_lines = []
    for index, label in enumerate(steps, 1):
        if index < current_step:
            icon = "✅"
        elif index == current_step:
            icon = "❌" if status == "failed" else "⏳"
        else:
            icon = "⏹"
        step_lines.append(f"{icon} <b>{html.escape(label)}</b>")

    repo = env("GITHUB_REPOSITORY")
    run_id = env("GITHUB_RUN_ID")
    run_url = f"https://github.com/{repo}/actions/runs/{run_id}"
    commit = env("LATEST_COMMIT", "pending")
    commit_url = env("COMMIT_URL")
    if commit_url and commit != "pending":
        commit_text = f'<a href="{html.escape(commit_url, quote=True)}"><code>{html.escape(commit)}</code></a>'
    else:
        commit_text = f"<code>{html.escape(commit)}</code>"

    if status == "failed":
        header = f"❌ <b>{html.escape(env('BUILD_LABEL', 'Recovery').upper())} BUILD FAILED</b>"
        footer = f'⚠️ Failed around step {current_step}. <a href="{html.escape(run_url, quote=True)}">Open logs</a>'
    elif percent >= 100:
        header = f"🎉 <b>{html.escape(env('BUILD_LABEL', 'Recovery').upper())} BUILT SUCCESSFULLY</b>"
        release_url = env("RELEASE_URL", run_url)
        footer = f'🚀 Completed in {elapsed_text(elapsed)}. <a href="{html.escape(release_url, quote=True)}">Download outputs</a>'
    else:
        header = "🛠 <b>RECOVERY BUILD DASHBOARD</b>"
        footer = f'<a href="{html.escape(run_url, quote=True)}">Open workflow run</a>'

    text = "\n".join(
        [
            header,
            "─────────────────────────────",
            f"📱 <b>Device:</b> <code>{html.escape(env('DEVICE_NAME', 'unknown'))}</code>",
            f"🌿 <b>Manifest:</b> <code>{html.escape(env('MANIFEST_BRANCH', 'unknown'))}</code> | <b>Target:</b> <code>{html.escape(env('BUILD_TARGET', 'recovery'))}</code>",
            f"🌲 <b>Device tree:</b> {commit_text}",
            "─────────────────────────────",
            f"📊 <b>Progress:</b> <code>[{bar}]</code> <b>{percent}%</b>",
            f"⏱ <b>Elapsed:</b> <code>{elapsed_text(elapsed)}</code> | ⌛ <b>Remaining:</b> <code>{remaining}</code>",
            "─────────────────────────────",
            "📌 <b>BUILD STEPS</b>",
            *step_lines,
            "─────────────────────────────",
            footer,
        ]
    )

    payload = {
        "chat_id": chat_id,
        "text": text,
        "parse_mode": "HTML",
        "disable_web_page_preview": "true",
    }

    try:
        if mode == "init":
            result = api_call("sendMessage", payload)
            message_id = result.get("result", {}).get("message_id")
            github_env = env("GITHUB_ENV")
            if message_id and github_env:
                with open(github_env, "a", encoding="utf-8") as output:
                    output.write(f"TG_MSG_ID={message_id}\n")
        else:
            message_id = env("TG_MSG_ID")
            if not message_id:
                return 0
            payload["message_id"] = message_id
            api_call("editMessageText", payload)
    except Exception as exc:
        print(f"Telegram notification warning: {exc}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
