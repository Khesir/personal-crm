import os


def read_brain_files(brain_path: str | None, brain_files: list[str]) -> str:
    if not brain_path or not brain_files:
        return ""

    parts = []
    for name in brain_files:
        file_path = os.path.join(brain_path, f"{name}.md")
        if os.path.exists(file_path):
            with open(file_path, "r", encoding="utf-8") as f:
                parts.append(f.read())

    return "\n\n".join(parts)
