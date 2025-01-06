# Source

The project's source repository can be found here: <https://github.com/jeffwhite530/Slurm-in-Kubernetes>

## What is in the project's files?

- **HashiCorp Packer Templates**: For building optimized Slurm container images
- **Ansible Playbooks**: For automated system configuration and service deployment
- **Helm Charts**: For packaging and simplified deployment
- **GitHub Action Templates**: For continuous integration/deployment pipelines
- **Documentation in Markdown**: For providing a GitHub Pages site using MkDocs

## Making changes

The `main` branch is protected and cannot be pushed to. A Pull Request from another branch is required.

When a PR is created, GitHub Actions Workflows found in `.github/workflows/` will be activated. These will run linters on the codebase. The workflows are configured to only run when certain files are changed. i.e. python-lint is only triggered when a .py files is changed.

The documentation site <https://jeffwhite530.github.io/Slurm-in-Kubernetes> is deployed by the workflow `.github/workflows/deploy-documentation.yaml`. It is triggered when a PR which changes a file in `docs/` is merged into the main branch. The site will be published to the gh-pages branch. Do not modify this branch.
