"""Preserve the Omarchy theme while disabling restricted Android probes."""
import pathlib
import re
import shutil

config = pathlib.Path("/home/omarchy/.config/btop/btop.conf")
config.parent.mkdir(parents=True, exist_ok=True)
backup = config.with_suffix(".conf.before-android")
if config.exists() and not backup.exists():
    shutil.copy2(config, backup)
text = config.read_text() if config.exists() else ""
settings = {
    "shown_boxes": '"cpu mem proc"',
    "show_disks": "false",
    "show_io_stat": "false",
    "show_cpu_freq": "false",
    "show_cpu_watts": "false",
    "check_temp": "false",
    "show_battery": "false",
}
for key, value in settings.items():
    pattern = rf"(?m)^{key}\s*=.*$"
    line = f"{key} = {value}"
    if re.search(pattern, text):
        text = re.sub(pattern, lambda _: line, text)
    else:
        text += "\n" + line + "\n"
config.write_text(text)
