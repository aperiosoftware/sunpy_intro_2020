#!/bin/env xonsh
"""
Publish all the notebooks by running them through the swc_formatter script.

Usage:
  publish_notebooks.xsh [--no-git]
"""

import sys
sys.path.append("")

import glob
import itertools
from pathlib import Path

from tqdm import tqdm

from preprocess_notebooks import process_notebook

current_dir = Path("./")
originals_dir = Path("./originals")
target_dir = Path("./notebooks")

old_files = itertools.chain(target_dir.rglob("*.ipynb"), target_dir.rglob("*.py"))
for file in old_files:
    rm @(file)


def gcwd(pattern):
    """
    Get files matching pattern in the main dir, without published or checkpoints.
    """
    dir_strip = ("notebooks", ".ipynb_checkpoints", ".tox", "Maps")
    return list(filter(lambda x: not any([d in x.parts for d in dir_strip]), originals_dir.rglob(pattern)))


files = gcwd("??-*.ipynb")

for afile in files:
    print(f'Processing {afile}')
    tfile = Path(*afile.parts[1:])
    target_file = target_dir/tfile
    target_file.parent.mkdir(parents=True, exist_ok=True)
    process_notebook(afile, target_file, strip_input=True)
    instructor_name = str(afile.name).replace(".ipynb", "_instructor.ipynb")
    process_notebook(afile, target_file.with_name(instructor_name), strip_input=False)

# Copy arbitary files
exclude_files = ("preprocess_notebooks.py",)

mkdir -p notebooks/data

for ext in ("svg", "png", "jpg", "py", "fits.gz", "csv", "tbl", "fits"):
    images = gcwd(f"*.{ext}")
    for afile in images:
        if any([excf in str(afile) for excf in exclude_files]):
            continue
        tfile = Path(*afile.parts[1:])
        target_file = target_dir/tfile
        cp @(afile) @(target_file)

if "--no-git" not in $ARGS:
    cd @(target_dir)
    git add .
    git commit -m "update notebooks"
    git push
    cd ../
    git add @(target_dir)
    git commit -m "update published notebooks"
