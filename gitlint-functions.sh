#!/bin/bash

# 

isFeatureBranch()
{
    refname="$1"

    shortname=$($GIT rev-parse --symbolic --abbrev-ref $refname 2>/dev/null)

    if [ $? != 0 ]; then
        echo false
        return
    fi

    case "$shortname" in
        */*)
            echo true
            return
            ;;
        *)
            ;;
    esac
    echo false

}


getGitlintCfg()
{
    HASH=$1
    TMPFILE=/tmp/gitlint.cfg.$$
    $GIT cat-file blob $HASH:$LOCAL_GITLINTCFG > $TMPFILE 2> /dev/null
    if [ $? != 0 ]; then
        rm -f $TMPFILE
        echo $GITLINTCFG
    else
        echo $TMPFILE
    fi
} 

cleanupGitlintCfg()
{
    TMPFILE=/tmp/gitlint.cfg.$$
    rm -f $TMPFILE
}

buildJiraRegexp()
{
    HOOKJIRAPROJECT=$($GIT config hook.jira-project)
    if [ -z "$HOOKJIRAPROJECT" ]; then
        return
    fi

    echo "\b$HOOKJIRAPROJECT\b-\d+\b"
}

