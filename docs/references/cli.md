# Command reference

Command reference gives users an understanding about programmatic options and expected behavior.
Ideally [reference](https://diataxis.fr/reference/) content is included in source code as docstrings or other markup that allows you to [automatically generate](https://www.sphinx-doc.org/en/master/tutorial/automatic-doc-generation.html) documentation.
This makes it easier to maintain documentation as part of the development workflow, which increases technical accuracy.
Putting reference content inline with code also helps to focus the docsite on task-oriented content and declutters user guides and so on.

Command reference typically follows the structure of manpages, which you can generate using [Sphinx](https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-manual-page-output)

Here are some sections that command reference should include:

## Description

The description gives a one or two sentence summary of the intended command usage.

## Synopsis

The synopsis gives a brief overview of the primary command usage.

## Options

Enumerate the options for each command and provide short description.

## Examples

Working examples that demonstrate actual command usage in a given environment.
