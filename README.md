# project-template
[![Discuss on Matrix at #community:ansible.com](https://img.shields.io/matrix/community:ansible.com.svg?server_fqdn=ansible-accounts.ems.host&label=Discuss%20on%20Matrix%20at%20%23community:ansible.com&logo=matrix)](https://matrix.to/#/#community:ansible.com)
[![Codecov badge](https://img.shields.io/codecov/c/github/ansible-community/project-template)](https://codecov.io/gh/ansible-community/project-template)

A GitHub repository template for new Ansible projects.

This template gives you the basic recommended (and in some instances required) files for your new Ansible community project.

## Template structure

This template includes sample files for the following:
- [Content in docs/](https://github.com/ansible-community/project-template/tree/main/docs) - A docsite template for your project that you are encouraged to use to provide a consistent experience to users and contributors across Ansible ecosystem projects. A website built from this template with [mkdocs](https://www.mkdocs.org/) is available on [ReadTheDocs](https://ansible.readthedocs.io/projects/ansible-project-template/en/latest/).
- [README.md](README.md) - This file. It should describe the project and list the documentation site, when available, and how to reach the project team (Matrix room, if available and Ansible forum tags). 
- [LICENSE.md](LICENSE.md) - The project license. We recommend GPLv3.
- [CONTRIBUTING.md](CONTRIBUTING.md) - The basics for contributing to your project. If your project has a docsite, refer to the docsite contributor guide from this CONTRIBUTING.md file.
- [SECURITY.md](SECURITY.md) - (optional) How to report security issues for your project.
- [CODE-OF-CONDUCT.md](CODE-OF-CONDUCT.md) - A link to the Ansible code of conduct. Do not change this.
- [DCO](DCO) - The Developer Certificate of Origin. Do not modify this text.

## Contributing to this template

You can open a GitHub issue to request changes or directly open a PR for small changes or enhancements.

# README.md template

> Make sure the following sections are present in your project's `README.md`

## Our mission

> Put you mission statement in here. Example follows.

At the `your project name`, our mission is to produce and maintain simple, flexible,
and powerful open-source software tailored to `your project purpose`.

We welcome members from all skill levels to participate actively in our open, inclusive, and vibrant community.
Whether you are an expert or just beginning your journey with Ansible and `your project name`,
you are encouraged to contribute, share insights, and collaborate with fellow enthusiasts!

## Code of Conduct

> If your project doesn't belong to GitHub orgs controlled by Red Hat, refer to a CoC violation complaint raising mechanism relevant to your project.

We follow the [Ansible Code of Conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html) in all our interactions within this project.

If you encounter abusive behavior violating the [Ansible Code of Conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html), please refer to the [policy violations](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html#policy-violations) section of the Code of Conduct for information on how to raise a complaint.

## Communication

> If your project has a docsite, this section should refer to a corresponding docsite section that contains the following information as on the [docsite index template page](https://github.com/ansible-community/project-template/blob/main/docs/index.md).

> If your project is not present on the Ansible forum yet, please check out the existing [tags](https://forum.ansible.com/tags) and [groups](https://forum.ansible.com/g) - use what suits the project. If there is no appropritate tag and group yet, please [request one](https://forum.ansible.com/t/requesting-a-forum-group/503/17).

* Join the Ansible forum:
    * [Get Help](https://forum.ansible.com/c/help/6): get help or help others.
    * [Posts tagged with 'your tag'](https://forum.ansible.com/tag/YOUR_TAG): subscribe to participate in project-related conversations.
    * [Refer to your forum group here if exists](https://forum.ansible.com/g/): by joining the team you will automatically get subscribed to the posts tagged with [your group forum tag here](https://forum.ansible.com/tags).
    * [Social Spaces](https://forum.ansible.com/c/chat/4): gather and interact with fellow enthusiasts.
    * [News & Announcements](https://forum.ansible.com/c/news/5): track project-wide announcements including social events.

* The Ansible [Bullhorn newsletter](https://docs.ansible.com/ansible/devel/community/communication.html#the-bullhorn): used to announce releases and important changes.

For more information about communication, see the [Ansible communication guide](https://docs.ansible.com/ansible/devel/community/communication.html).

## Contributing to this project

### How to open an issue

If you want to report a bug or request a new feature, please:
1. Search in the [issues](https://github.com/ORG/REPO/issues) for similar reports/requests.
2. If there are already no such issues, open a new one by clicking the `New issue` button.

### Contributor guidelines

> Use one source of truth: it can be a contributing section on project docsite or CONTRIBUTING.md. If you have a docsite, use it.

To learn how to contribute to this project, see the [Contributor guidelines](https://link-to-docsite-or-contributor.md).

### Getting started development guide

> If the project doesn't have the guide, please add it to mitigate the entry threshold for new contributors. If it's not applicable, remove  the section.

Do you have a fix and want to submit a ready-for-merge pull request? See the [Getting started development guide](https://link-to-the-quide).

## Releasing

> Please replace the content in the sub-sections below with information relevant to your project.

> If you have the same information covered on the project docsite, refer to the corresponding docsite pages instead. 

### Versioning specification

To determine a software version number when releasing, this project uses the [Semantic Versioning Specification](https://semver.org/) to convey meaning about what has been modified from one version to the next.

### Release policy & maintenance timeline

> Describe your release policy and maintenance timeline in this section or refer to a corresponding docsite page.

We maintain each major release version (1.x.y, 2.x.y,...) for two years after the next major version is released.

Here is the table for the support timeline:

- `1.x.y`: released 2020-11-17, EOL
- `2.x.y`: released 2022-02-10, supported until 2025-06-09
- `3.x.y`: released 2023-06-09, current

### Release notes

> Embed a link to a project changelog into here.

For release notes, see the [changelog]().

## Governance

> Update this section with relevant information and URLs. If the project has a docsite, include this information in the docsite.

The process of decision making in this project is based on discussing and finding consensus among participants.

We, [Refer to your forum group here](https://forum.ansible.com/g/YOUR-GROUP), use [the forum](https://forum.ansible.com/tag/YOUR-TAG) posts tagged with `TAGNAME` for general announcements and discussions. If you have something on your mind, just create a [post](https://forum.ansible.com/new-topic?title=topic%20title&body=topic%20body&category=project&tags=YOUR-TAG) and let's find the best solution together!
