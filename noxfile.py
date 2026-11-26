import nox


@nox.session
def build(session: nox.Session):
    """
    Build the AWX Operator Helm Chart docsite.
    """
    session.install(
        "-r",
        "docs/requirements.txt",
    )
    session.run(
        "zensical",
        "build",
        "--strict",
        *session.posargs,
    )
