#!/usr/bin/env python3

import difflib
import glob
import os

# ----------------------------------------
# Helper functions
# ----------------------------------------


def read_map_file(path):
    """
    Reads lines like:
    /home/me/.config/omf/specificfile|/home/me/myproject/configs/omf/*
    return tuple of (left, right)
    """
    mappings = []
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if not line or "|" not in line:
                continue
            left, right = line.split("|")
            mappings.append((left.strip(), right.strip()))
    return mappings


def resolve_mapping(original_pattern, current_pattern):
    """
    Resolves a single mapping entry into a list of (original_file, current_file).
    Handles:
    - file → file
    - file → dir/*
    - dir/* → dir/*
    """
    original_files = glob.glob(original_pattern, recursive=True)
    current_files = glob.glob(current_pattern, recursive=True)

    # If original is a single file and current ends with *, match filename only
    pairs = []

    if "*" not in original_pattern and "*" in current_pattern:
        # Map specific file → directory pattern
        if original_files:
            base = os.path.basename(original_files[0])
            candidates = [f for f in current_files if os.path.basename(f) == base]
            if candidates:
                pairs.append((original_files[0], candidates[0]))
        return pairs

    # Directory → directory mapping
    if "*" in original_pattern and "*" in current_pattern:
        original_dict = {os.path.basename(p): p for p in original_files}
        current_dict = {os.path.basename(p): p for p in current_files}

        for key in original_dict:
            if key in current_dict:
                pairs.append((original_dict[key], current_dict[key]))
        return pairs

    # Simple file → file
    if len(original_files) == 1 and len(current_files) == 1:
        pairs.append((original_files[0], current_files[0]))
        return pairs

    return pairs


def files_differ(f1, f2):
    """
    Returns True if file contents differ.
    """
    try:
        with open(f1, "r") as a, open(f2, "r") as b:
            return a.read() != b.read()
    except Exception:
        return True


# ----------------------------------------
# Main logic
# ----------------------------------------


def main():
    map_file = "filemap"
    mappings = read_map_file(map_file)

    differing = []

    for original, current in mappings:
        file_pairs = resolve_mapping(original, current)

        for orig_f, curr_f in file_pairs:
            if not os.path.exists(orig_f) or not os.path.exists(curr_f):
                differing.append((orig_f, curr_f))
                continue

            if files_differ(orig_f, curr_f):
                differing.append((orig_f, curr_f))

    # Directory diff support (commented)
    # import filecmp
    # cmp = filecmp.dircmp(dir1, dir2)
    # if cmp.left_only or cmp.right_only or cmp.diff_files:
    #     differing.append((dir1, dir2))

    if differing:
        print("Differences detected:")
        for o, c in differing:
            print(f"- {o}  <->  {c}")
    else:
        print("No differences")


if __name__ == "__main__":
    main()
