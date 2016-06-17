gitlint hook for gitolite
=========================

A wrapper around [gitlint](http://jorisroovers.github.io/gitlint/) to support using it as a pre-receive hook within a [gitolite](http://gitolite.com/gitolite/index.html) installation.   

Supports configuration:

* a default gitlint.cfg file stored on the gitolite server
* basic customizations via git repository options.
* an optional per-repository (or per branch) gitlint.cfg file.

We use this as a repo-specific hook in gitolite, but I don't see any reason it couldn't be used as a common hook instead if you wanted it for all repositories.

## Installation

### Requirements

* `gitolite` should be installed and running.
* `gitlint` should be installed on the gitolite server

### Gitolite configuration

* `GIT_CONFIG_KEYS` should be set to include `hook.*` in `.gitolite.rc`:

```
         GIT_CONFIG_KEYS                 =>  'hook.*',
```
* `LOCAL_CODE` should be set to either a local directory, or a directory within your `gitolite-admin` repository:

```
	      LOCAL_CODE                =>  "$rc{GL_ADMIN_BASE}/local",
``` 

### Installation
* Copy the `gitlint-functions.sh` and `gitlint.cfg` files to somewhere in the local tree where they wont be accidentally executed themselves, e.g.  `local/hooks/`. 
* Modify `gitlint.cfg` to suit your preferences.
* Copy `gitlint-hook` to `local/hooks/repo-specific/` and modify it, setting the paths at the top appropriately for your installation.

### Repository configuration

To enable the repo-specific hook for a repository, add the following to your repository's `gitolite.conf` entry:

```
repo myRepository
	option hook.pre-receive = gitlint-hook
```

There are three git options which impact its behavior:

1. `hook.gitlint = <bool>`  Defaults to false.  Enables the hook. At some point we may toggle this to true by default, and make projects disable it if desired.
2. `hook.gitlint-ignore-feature-branches = <bool>`  Causes the hook to skip running when pushes are made to feature branches. Feature branches are defined as branches with a / in the name, for example, `feature/blah` or `<username>/PROJECT-123-some-feature`. Project may want to enforce well formed commits on feature branches, or they may want to allow the developer to run wild on the branch, assuming that it will be cleaned up in a nice merge commit to the sprint branch (note that if the developer tries to do a fast-forward merge to a non-feature branch, it will need to conform to the commit message standards)
3. `hook.jira-project`  Provides the project key which is used to build a regular expression which is required to be found in the commit "title" or first line.

If a project desires more control, the script will look in the repository (on the tip of the branch being pushed to) for a file called `.gitlint.cfg` which is documented on the gitlint site, and use that in place of the default.  Note that it may be possible to get yourself in a somewhat bad situation where your local `.gitlint.cfg` causes all pushes to be rejected, which makes it hard to fix.   In that case, you'll probably need to disable the hook for your repository while you fix the file.  


### Examples

#### Single repository

```
repo testing
        RW+     =   @all
        option hook.pre-receive = gitlint-hook
        config hook.gitlint = true
        config hook.gitlint-ignore-feature-branches = true
        config hook.jira-project = TESTING
```

#### Defaults for multiple repositories

```
@repos = repo1 repo2 repo3

repo @repos
        RW+     =   @all
        option hook.pre-receive = gitlint-hook
        config hook.gitlint = true
        config hook.gitlint-ignore-feature-branches = true

# repo1 just wants to customize the regexp required.
repo repo1
        config hook.jira-project = REPO1

# we want to be strict for repo2 - enforce on feature branches
repo repo2
        config hook.jira-project = REPO2
        config hook.gitlint-ignore.feature-branches = false  

# repo3 wants to disable checking entirely
repo repo2
        config hook.gitlint = false
       				 

```		


