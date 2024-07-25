# Getting started with PROJECTNAME

Projects should provide users with a getting started guide.
The purpose of a getting started guide is to increase adoption and remove barriers to entry for your project.
Users should be able to complete the steps in approximately five minutes.

Your project's getting started guide should give users a first quick success.
In general, user should install the project, quickly verify the installation, and run one or two commands.
The commands in your project's getting started guide should do something basic but illustrate your project's core functionality.
If appropriate, consider providing sample configuration values and artifacts that allow users to run code locally.

> The following steps are intended to give an idea of a reasonable getting started guide with an example project named "ansible-project".

1. Install `ansible-project`.

   ```bash
   pip install ansible-project
   ```

2. Check your installation.

   ```bash
   ansible-project --version
   ```

3. Run a command that demonstrates basic functionality.

   ```bash
   ansible-project automate --target=user_success
   ```

4. Verify the command was successful.

Now you've completed your first task with `ansible-project`!

> Add some links to materials that users should refer to as next steps.
> Encourage your users to continue learning and gain new skills with your project.
