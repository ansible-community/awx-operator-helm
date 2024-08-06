#!/usr/bin/env python
"""
Clone relevant portions of the AWX Operator from ansible/awx-operator into the current
source tree to facilitate building the Helm chart.
"""

from __future__ import annotations

import argparse
import dataclasses
import pathlib
import shutil
import subprocess
import sys
import tempfile

DEFAULT_BRANCH = "devel"
DEFAULT_AWX_OPERATOR_REPO = "https://github.com/ansible/awx-operator"


@dataclasses.dataclass()
class Args:
    branch: str | None
    repo: str


def parse_args(args: list[str] | None = None) -> Args:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "-b",
        "--branch",
        help="Set the branch of awx-operator to clone."
        " Defaults to current branch (%(default)s)",
        default=DEFAULT_BRANCH,
    )
    parser.add_argument(
        "--no-branch",
        help="Checkout the default git branch of --remote."
        " This is useful when cloning a local awx-operator fork",
        dest="branch",
        action="store_const",
        const=None,
    )
    parser.add_argument(
        "--repo",
        help="awx-operator repository to check out. Default: %(default)s",
        default=DEFAULT_AWX_OPERATOR_REPO,
    )
    return Args(**vars(parser.parse_args(args)))


def main(args: Args) -> None:
    keep_dirs = [
        "config",
        "playbooks",
        "roles",
        "vendor",
    ]

    keep_files = [
        "Dockerfile",
        "requirements.yml",
        "watches.yaml",
    ]

    with tempfile.TemporaryDirectory() as temp_dir:
        cmd: list[str] = ["git", "clone", args.repo, "--depth=1"]
        if args.branch is not None:
            cmd.append(f"--branch={args.branch}")
        cmd.append(temp_dir)
        subprocess.run(cmd, check=True)

        for keep_dir in keep_dirs:
            src = pathlib.Path(temp_dir, keep_dir)
            dst = pathlib.Path.cwd() / keep_dir

            print(f"Updating {keep_dir!r} ...", file=sys.stderr, flush=True)

            if dst.exists():
                shutil.rmtree(dst)

            shutil.copytree(src, dst, symlinks=True)

            (dst / ".gitignore").write_text("*")

        for keep_file in keep_files:
            src = pathlib.Path(temp_dir, keep_file)
            dst = pathlib.Path.cwd() / keep_file

            print(f"Updating {keep_file!r} ...", file=sys.stderr, flush=True)

            shutil.copyfile(src, dst)


if __name__ == "__main__":
    main(parse_args())
