#!/bin/bash
# Calculate git push operation time to GitHub and MS VSTS.
# Script firstly clones forked che-core, then goes into branch perfTest.
# After that, during the iteration, it creates small random modification in a file,
# commits and force pushes this branch to GitHub and VSTS remotes
# ATTEMPTS. Cloning will happen in the directory, where the script is launched,
# Also, che-core direcotry will be removed before and after execution.
# In result, there will be written data in the following format:
#
#	Attemp X:
#	GitHub start: hh:mm:ss
#	GitHub end  : hh:mm:ss
#	GitHub time : XXm:XXs
#	VSTS start  : hh:mm:ss
#	VSTS end    : hh:mm:ss
#	VSTS time   : XXm:XXs
#	=============================
#
# For each attempt. In the end, a max/min time for each type of operation, as well
# as average calculation errors will be noted. All calculations are done with integer
# numbers, so there is an extra error in calculation up to 1 sec.
#
# Results will be provided in "push-result" file, it will be rewritten after each execution.
#

getDateFromTimestamp() {
    local cmdLineOption="--date @"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # on MacOS --date is not an option
        cmdLineOption="-r "
    fi

    echo $(date ${cmdLineOption}${1} +%T)
}

# GitHub URL should lead to repository where you have full and safe read-write access.
# In this case it is a personal fork
GITHUB_URL=https://github.com/mkuznyetsov/che-core.git
VSTS_URL=https://che-1.visualstudio.com/DefaultCollection/test/_git/che-core

ATTEMPTS=10

GITHUB_TOTAL_TIME=0
GITHUB_MIN_TIME=99999999
GITHUB_MAX_TIME=0

VSTS_TOTAL_TIME=0
VSTS_MIN_TIME=99999999
VSTS_MAX_TIME=0

# initial cleanup
rm push-results
rm -rf che-core

# clone forked che-core (with perfTest branch)
git clone GITHUB_URL
cd che-core
git checkout -b perfTest
git remote add msoft $VSTS_URL


for (( i=1; i<=$ATTEMPTS; i++ ))
do
    echo "Attempt $i:"

    echo $(date "+%s") > timestamp
    git add -A
    git commit -m "timestamp"

    GITHUB_START_TIME=$(date "+%s")
    git push origin perfTest -fu
    GITHUB_END_TIME=$(date "+%s")
    GITHUB_TIME_DIFF=$(( ${GITHUB_END_TIME} - ${GITHUB_START_TIME} ))

    GITHUB_MINUTES_DIFF=$(( ${GITHUB_TIME_DIFF} / 60 ))
    GITHUB_SECONDS_DIFF=$(( ${GITHUB_TIME_DIFF} - ${GITHUB_MINUTES_DIFF} * 60 ))

    rm -rf che-core

    VSTS_START_TIME=$(date "+%s")
    git push msoft perfTest -fu
    VSTS_END_TIME=$(date "+%s")

    VSTS_TIME_DIFF=$(( ${VSTS_END_TIME} - ${VSTS_START_TIME} ))
    VSTS_MINUTES_DIFF=$(( ${VSTS_TIME_DIFF} / 60 ))
    VSTS_SECONDS_DIFF=$(( ${VSTS_TIME_DIFF} - ${VSTS_MINUTES_DIFF} * 60 ))

    echo "Result: $i" >> push-results
    echo "GitHub start :"$(getDateFromTimestamp $GITHUB_START_TIME) >> push-results
    echo "Github end   :"$(getDateFromTimestamp $GITHUB_END_TIME) >> push-results
    echo "Github time  : ${GITHUB_MINUTES_DIFF}m:${GITHUB_SECONDS_DIFF}s" >> push-results
    echo "VSTS start   :"$(getDateFromTimestamp $VSTS_START_TIME) >> push-results
    echo "VSTS end     :"$(getDateFromTimestamp $VSTS_END_TIME) >> push-results
    echo "VSTS time    : ${VSTS_MINUTES_DIFF}m:${VSTS_SECONDS_DIFF}s" >> push-results
    echo "==============================" >> push-results

    # cleanup
    rm -rf che-core
done

echo "GitHub max time    : ${GITHUB_MAX_TIME}" >> push-results
echo "GitHub min time    : ${GITHUB_MIN_TIME}" >> push-results
echo "GitHub average time: $(( ${GITHUB_TOTAL_TIME} / ${ATTEMPTS} ))" >> push-results
echo "GitHub calc error  : $(( ( ${GITHUB_MAX_TIME} - ${GITHUB_MIN_TIME} ) / 2 ))" >> push-results
echo "-------------------------------------"
echo "VSTS max time    : ${VSTS_MAX_TIME}" >> push-results
echo "VSTS min time    : ${VSTS_MIN_TIME}" >> push-results
echo "VSTS average time: $(( ${VSTS_TOTAL_TIME} / ${ATTEMPTS} ))" >> push-results
echo "VSTS calc error  : $(( ( ${VSTS_MAX_TIME} - ${VSTS_MIN_TIME} ) / 2 ))" >> push-results
