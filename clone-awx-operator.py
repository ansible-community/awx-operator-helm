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

DEFAULT_AWX_OPERATOR_REPO = "https://github.com/ansible/awx-operator"

# get the appVersion configured in Chart.yaml
def get_app_version():
    try:
        chart_yaml_path = "./.helm/starter/Chart.yaml"
        with open(chart_yaml_path) as chart:
            for line in chart:
                if line.startswith("appVersion:"):
                    print(f"Looking at line {line}")
                    result = line.split(":", 1)
                    if len(result) != 2:
                        raise KeyError("Malformed appVersion in Chart.yaml")
                    app_version = result[1].strip()
                    print(f"pre strip |||{result[1]}|||")
                    if not app_version:
                        raise KeyError("No appVersion value found")
                    return app_version
    except FileNotFoundError:
        raise FileNotFoundError("Failed to open Chart.yaml")
    raise KeyError("Could not find appVersion in Chart.yaml")

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
        " Defaults to configured appVersion",
        default=get_app_version(),
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
        "Makefile",
        "requirements.yml",
        "watches.yaml",
    ]

    with tempfile.TemporaryDirectory() as temp_dir:
        cmd: list[str] = [
            "git",
            "clone",
            args.repo,
            "--depth=1",
            "-c advice.detachedHead=false",
        ]
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
            if keep_file == 'Makefile':
                dst = pathlib.Path.cwd() / "Makefile.awx-operator"
            else:
                dst = pathlib.Path.cwd() / keep_file

            print(f"Updating {keep_file!r} ...", file=sys.stderr, flush=True)

            shutil.copyfile(src, dst)


if __name__ == "__main__":
    main(parse_args())
