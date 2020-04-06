## Releasing
Follow these instructions to create a new release for a version.

### Create Jenkins job
If not already setup create a Jenkins pipeline job with the following parameters

Pipeline name: gwa-ip-anonymity-release

Discard old builds:
  Max # of builds to keep: 2

This Project is parameterized: Yes
  Choice Parameter
    Name: gitBranch
    Choices: master (more can be added if used)
  String Parameter
    Name: gitTag
    Trim the string: yes
  Passord Parameter
    Name: luarocksApiKey
    Default value: A luarocks.org api Key

Definiion: Pipeline script from SCM
  SCM: git
  Repositories:
    Repository URL: git@github.com:bcgov/gwa-ip-anonymity.git
    Credentials: A personal access token credential for a github.com user with write permission for the repository
  Branches to build: */jenkins-release
  Script path: Jenkinsfile
  Lightweight checkout: Yes
  
### Running Jenkins job
The jenkins job will update the version in the source code and deploy to luarocks

1. Click Build with Parameters on the job.
2. Select the gitBranch (e.g. master).
3. Enter the gitTag (e.g. 1.0.0) which is the version number of the release.
4. Enter the luarocksApiKey (if not set as a default).
5. Click build.
