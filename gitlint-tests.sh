#!/bin/bash

GIT=/usr/bin/git

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
$GIT init
    

touch test-file
git add test-file
git commit -m 'initial commit'
git branch develop
git branch release-1.0-branch
git branch feature/foo
git branch user/bob

FB=$(isFeatureBranch develop)
if [ "false" != "$FB" ]; then
    echo "FAIL isFeatureBranch develop"
fi
FB=$(isFeatureBranch release-1.0-branch)
if [ "false" != "$FB" ]; then
    echo "FAIL isFeatureBranch release-1.0-branch"
fi
FB=$(isFeatureBranch feature/foo)
if [ "true" != "$FB" ]; then
    echo "FAIL isFeatureBranch feature/foo"
fi
FB=$(isFeatureBranch user/bob)
if [ "true" != "$FB" ]; then
    echo "FAIL isFeatureBranch user/bob"
fi
FB=$(isFeatureBranch unknown-branch)
if [ "false" != "$FB" ]; then
    echo "FAIL isFeatureBranch unknown-branch"
fi
FB=$(isFeatureBranch feature/unknown)
if [ "false" != "$FB" ]; then
    echo "FAIL isFeatureBranch feature/unknown"
fi


revision=$(git describe --always --long)


cfg=$( getGitlintCfg $revision )

if [ "$cfg" != "$GITLINTCFG" ]; then
    echo "FAIL: getGitlintCfg didnt return global"
fi

if [ -f "/tmp/gitlint.cfg.$$" ]; then
    echo "FAIL: getGitlintCfg created temporary"
fi

cleanupGitlintCfg


cp $GITLINTCFG ./.gitlint.cfg
git add .
git commit -m 'add gitlint.cfg'

revision=$(git describe --always --long)

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


cd $STARTDIR
rm -rf $TESTREPO
