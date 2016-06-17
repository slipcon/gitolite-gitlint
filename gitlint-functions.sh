#!/bin/bash

isFeatureBranch()
{
    refname="$1"

    # if its a tag, its not a feature branch
    if [[ $refname == refs/tags/* ]]; then
        echo false
        return
    fi

    shortname=$($GIT rev-parse --symbolic --abbrev-ref $refname 2>/dev/null)

    if [ $? != 0 ]; then
        # ok so refname isn't found.... but it could be a new branch:

        if [[ $refname == refs/heads/* ]]; then
            shortname=${refname#refs/heads/}  # pull off the refs/heads bit
        else
            echo false
            return
        fi
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

    echo "-c T7.regex=\b$HOOKJIRAPROJECT\b-\d+\b"
}

validate_ref()
{
    # borrowed and adapted from https://github.com/andygrunwald/jitic

    # Arguments
    oldrev=$($GIT rev-parse $1)
    newrev=$($GIT rev-parse $2)
    refname="$3"

    # $oldrev / $newrev are commit hashes (sha1) of git
    # $refname is the full name of branch (refs/heads/*) or tag (refs/tags/*)
    # $oldrev could be 0s which means creating $refname
    # $newrev could be 0s which means deleting $refname

    case "$refname" in
        refs/heads/*)
            # Pushing a branch delete...
            if [ 0 -ne $(expr "$newrev" : "0*$") ]; then
                COMMITS_TO_CHECK=""  # nothing to do

            # Pushing a new branch
            elif [ 0 -ne $(expr "$oldrev" : "0*$") ]; then
                COMMITS_TO_CHECK=$($GIT rev-list $newrev --not --branches=*)

            # Updating an existing branch
            else
                COMMITS_TO_CHECK=$($GIT rev-list $oldrev..$newrev)
            fi

            # If we push an new, but empty branch we can exit early.
            # In this case there are no commits to check.
            if [ -z "$COMMITS_TO_CHECK" ]; then
                return
            fi

            CFG=$( getGitlintCfg $newrev )
            REGEX=$( buildJiraRegexp )

            # Get all commits, loop over and check if the comments are valid
            while read REVISION ; do
                $GIT log --pretty=format:"%B" -n 1 $REVISION | $GITLINT -vvv -C $CFG $REGEX
                if [ $? != 0 ]; then
                    FAIL=1
                    echo >&2 "... in revision $REVISION"
                fi
            done <<< "$COMMITS_TO_CHECK"

            cleanupGitlintCfg

            return
            ;;
        refs/tags/*)
            # Support for tags (new / delete) needs to be done.
            # Things we need to check:
            #   * Get all commits from the new tag that are NOT checked yet
            #     (checked means by jitic). Something like commits which are
            #     not pushed yet, but the tag was pushed.
            # I think we don`t need to care about deleted branches yet.
            ;;
        *)
            FAIL=1
            echo >&2 ""
            echo >&2 "*** pre-receive hook does not understand ref $refname in this repository. ***"
            echo >&2 "*** Contact the repository administrator. ***"
            echo >&2 ""
            ;;
    esac
}
