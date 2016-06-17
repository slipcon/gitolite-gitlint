#!/bin/bash

# Test program assumes git and gitlint are in the $PATH - but the functions
# use these variables, since we don't really know the environment that will
# be used from the hooks.

GIT=git
GITLINT=gitlint

FUNCTIONS="gitlint-functions.sh"
GITLINTCFG=$(pwd)/gitlint.cfg
LOCAL_GITLINTCFG=.gitlint.cfg

. $FUNCTIONS

TESTREPO="/tmp/test-repo"

if [ -d $TESTREPO ]; then
    echo "$TESTREPO already exists, aborting!";
    exit 1;
fi

STARTDIR=$(pwd)
mkdir $TESTREPO
cd $TESTREPO
$GIT init > /dev/null

touch test-file
$GIT add test-file > /dev/null
$GIT commit -m 'initial commit' > /dev/null
$GIT branch develop
$GIT branch release-1.0-branch
$GIT branch feature/foo
$GIT branch user/bob

FB=$(isFeatureBranch refs/heads/develop)
if [ "false" != "$FB" ]; then
    echo "FAIL isFeatureBranch develop"
fi
FB=$(isFeatureBranch refs/heads/release-1.0-branch)
if [ "false" != "$FB" ]; then
    echo "FAIL isFeatureBranch release-1.0-branch"
fi
FB=$(isFeatureBranch refs/heads/feature/foo)
if [ "true" != "$FB" ]; then
    echo "FAIL isFeatureBranch feature/foo"
fi
FB=$(isFeatureBranch refs/heads/user/bob)
if [ "true" != "$FB" ]; then
    echo "FAIL isFeatureBranch user/bob"
fi
FB=$(isFeatureBranch refs/heads/unknown-branch)
if [ "false" != "$FB" ]; then
    echo "FAIL isFeatureBranch unknown-branch"
fi
FB=$(isFeatureBranch refs/heads/feature/unknown)
if [ "true" != "$FB" ]; then
    echo "FAIL isFeatureBranch feature/unknown"
fi
FB=$(isFeatureBranch refs/tags/v1.0.0)
if [ "false" != "$FB" ]; then
    echo "FAIL isFeatureBranch v1.0.0 tag"
fi

$GIT tag v0.9.0
FB=$(isFeatureBranch refs/tags/v0.9.0)
if [ "false" != "$FB" ]; then
    echo "FAIL isFeatureBranch v0.9.0 tag"
fi

revision=$($GIT describe --always --long)


cfg=$( getGitlintCfg $revision )

if [ "$cfg" != "$GITLINTCFG" ]; then
    echo "FAIL: getGitlintCfg didnt return global"
fi

if [ -f "/tmp/gitlint.cfg.$$" ]; then
    echo "FAIL: getGitlintCfg created temporary"
fi

cleanupGitlintCfg

cp $GITLINTCFG ./.gitlint.cfg
$GIT add . > /dev/null
$GIT commit -m 'add gitlint.cfg' > /dev/null

revision=$($GIT describe --always --long)

cfg=$( getGitlintCfg $revision )
if [ "$cfg" == "$GITLINTCFG" ]; then
    echo "FAIL: getGitlintCfg returned global"
fi

if [ ! -f "/tmp/gitlint.cfg.$$" ]; then
    echo "FAIL: getGitlintCfg didn't create temporary"
fi

cleanupGitlintCfg

if [ -f "/tmp/gitlint.cfg.$$" ]; then
    echo "FAIL: cleanupGitlintCfg didn't clean temporary"
fi


cfg=$( getGitlintCfg $revision )
regex=$( buildJiraRegexp )
echo
echo "Expect no gitlint fails:"
cat $STARTDIR/test1.txt | $GITLINT -C $cfg $regex 
cat $STARTDIR/test2.txt | $GITLINT -C $cfg $regex 
cat $STARTDIR/test3.txt | $GITLINT -C $cfg $regex 

$GIT config --local --add hook.jira-project PROJ
regex=$( buildJiraRegexp )
echo
echo "Expect two gitlint fails:"
cat $STARTDIR/test1.txt | $GITLINT -C $cfg $regex 
cat $STARTDIR/test2.txt | $GITLINT -C $cfg $regex 
cat $STARTDIR/test3.txt | $GITLINT -C $cfg $regex 

cleanupGitlintCfg

startrev=$($GIT describe --always --long)

echo one >> test-file
$GIT commit -a -F $STARTDIR/test1.txt > /dev/null
echo two >> test-file
$GIT commit -a -F $STARTDIR/test2.txt > /dev/null
echo three >> test-file
$GIT commit -a -F $STARTDIR/test3.txt > /dev/null

endrev=$($GIT describe --always --long)

echo
echo "Running validate_ref: expect two gitlint fails:"
validate_ref $startrev $endrev refs/heads/master

cd $STARTDIR
rm -rf $TESTREPO
