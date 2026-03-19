#!/usr/bin/env python3
"""Tiny HTTP server that shows macOS notifications when POSTed to.
Run on your Mac. Devbox reaches it via SSH reverse tunnel."""

from http.server import HTTPServer, BaseHTTPRequestHandler
import os
import shutil
import subprocess
import json

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SWITCH_SCRIPT = os.path.join(SCRIPT_DIR, "switch-cursor-window.sh")
SWITCH_TMUX_SCRIPT = os.path.join(SCRIPT_DIR, "switch-tmux-pane.sh")


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(length)) if length else {}
        msg = body.get("message", "Claude Code needs attention")
        sound = body.get("sound", "Glass")
        folder = body.get("folder", "")
        is_ssh = body.get("ssh", False)
        tmux_target = body.get("tmux_target", "")
        tmux_socket = body.get("tmux_socket", "")

        if tmux_target:
            execute_cmd = f'{SWITCH_TMUX_SCRIPT} "{tmux_socket}" "{tmux_target}"'
        else:
            execute_cmd = f'{SWITCH_SCRIPT} "{folder}" {"ssh" if is_ssh else "local"}'

        notifier = (
            shutil.which("terminal-notifier")
            or (
                "/opt/homebrew/bin/terminal-notifier"
                if os.path.exists("/opt/homebrew/bin/terminal-notifier")
                else None
            )
        )
        if notifier:
            subprocess.Popen(
                [
                    notifier,
                    "-title", "Claude Code",
                    "-message", msg,
                    "-sound", sound,
                    "-execute", execute_cmd,
                ]
            )
        self.send_response(200)
        self.end_headers()

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    server = HTTPServer(("127.0.0.1", 19418), Handler)
    print("Claude notify server listening on 127.0.0.1:19418")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
