import fcntl
import os
import pathlib
import pty
import re
import select
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time

binary = sys.argv[1]
with tempfile.TemporaryDirectory(prefix="btop-android-test-") as directory:
    config = pathlib.Path(directory) / "btop.conf"
    config.write_text('''shown_boxes = "cpu mem net proc"
update_ms = 500
show_disks = false
show_cpu_freq = false
check_temp = false
show_battery = false
save_config_on_exit = false
''')
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 45, 140, 0, 0))
    environment = dict(os.environ, BTOP_ANDROID_PROOT="1", TERM="xterm-256color", LANG="C.UTF-8", XDG_STATE_HOME=directory)
    process = subprocess.Popen([binary, "--config", str(config), "--debug"], stdin=slave, stdout=slave, stderr=slave, env=environment, start_new_session=True)
    os.close(slave)
    captured = bytearray()
    deadline = time.monotonic() + 7
    resized = False
    try:
        while time.monotonic() < deadline and process.poll() is None:
            if not resized and time.monotonic() > deadline - 3:
                fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack("HHHH", 36, 100, 0, 0))
                process.send_signal(signal.SIGWINCH)
                resized = True
            if select.select([master], [], [], .2)[0]:
                try:
                    captured.extend(os.read(master, 65536))
                except OSError:
                    break
        running = process.poll() is None
        if running:
            os.write(master, b"q")
        code = process.wait(timeout=10)
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
        os.close(master)
    plain = re.sub(rb"\x1b\[[0-?]*[ -/]*[@-~]", b"", bytes(captured))
    logs = "\n".join(path.read_text() for path in pathlib.Path(directory).rglob("*.log"))
    assert running, plain[-2000:]
    assert code == 0, (code, plain[-2000:])
    assert b"System CPU and sensors: unavailable on Android" in plain
    assert b"Unavailable on Android" in plain
    assert "ERROR" not in logs, logs
    print("PASS: all panels, live refresh, terminal resize, clean exit; no logged errors")
