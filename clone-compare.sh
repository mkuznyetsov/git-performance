#!/bin/bash
# Calculate git clone operation time from GitHub and MS VSTS.
# Script performs cloning of che-core multiple times, that are defined by variable
# ATTEMPTS. Cloning will happen in the directory, where the script is launched,
# so it will be rewritten after each iteration. Also, che-core direcotry will be
# removed before and after execution.
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
# Results will be provided in "clone-result" file, it will be rewritten after each execution. 
#

getDateFromTimestamp() {
    local cmdLineOption="--date @"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # on MacOS --date is not an option
        cmdLineOption="-r "
    fi

    echo $(date ${cmdLineOption}${1} +%T)
}

GITHUB_URL=https://github.com/codenvy/che-core.git
VSTS_URL=https://che-1.visualstudio.com/DefaultCollection/test/_git/che-core
ATTEMPTS=2

GITHUB_TOTAL_TIME=0
GITHUB_MIN_TIME=99999999
GITHUB_MAX_TIME=0

VSTS_TOTAL_TIME=0
VSTS_MIN_TIME=99999999
VSTS_MAX_TIME=0

# initial cleanup
rm clone-results
rm -rf che-core


for (( i=1; i<=$ATTEMPTS; i++ ))
do
    echo "Attempt $i:"

    GITHUB_START_TIME=$(( $(date "+%s") ))
    git clone ${GITHUB_URL}
    GITHUB_END_TIME=$(( $(date "+%s") ))
    GITHUB_TIME_DIFF=$(( ${GITHUB_END_TIME} - ${GITHUB_START_TIME} ))

    GITHUB_MINUTES_DIFF=$(( ${GITHUB_TIME_DIFF} / 60 ))
    GITHUB_SECONDS_DIFF=$(( ${GITHUB_TIME_DIFF} - ${GITHUB_MINUTES_DIFF} * 60 ))

    GITHUB_TOTAL_TIME=$(( $GITHUB_TIME_DIFF + $GITHUB_TOTAL_TIME ))
    if [[ $GITHUB_MAX_TIME -lt $GITHUB_TIME_DIFF ]]; then
	GITHUB_MAX_TIME=${GITHUB_TIME_DIFF}
    fi

    if [[ $GITHUB_MIN_TIME -gt $GITHUB_TIME_DIFF ]]; then
	GITHUB_MIN_TIME=${GITHUB_TIME_DIFF} 
    fi

    # cleanup
    rm -rf che-core

    VSTS_START_TIME=$(date "+%s")
    git clone ${VSTS_URL}
    VSTS_END_TIME=$(date "+%s")
    VSTS_TIME_DIFF=$(( ${VSTS_END_TIME} - ${VSTS_START_TIME} ))

    VSTS_MINUTES_DIFF=$(( ${VSTS_TIME_DIFF} / 60 ))
    VSTS_SECONDS_DIFF=$(( ${VSTS_TIME_DIFF} - ${VSTS_MINUTES_DIFF} * 60 ))

    VSTS_TOTAL_TIME=$(( $VSTS_TIME_DIFF + $VSTS_TOTAL_TIME ))
    if [[ $VSTS_MAX_TIME -lt $VSTS_TIME_DIFF ]]; then
        VSTS_MAX_TIME=${VSTS_TIME_DIFF}
    fi

    if [[ $VSTS_MIN_TIME -gt $VSTS_TIME_DIFF ]]; then
        VSTS_MIN_TIME=${VSTS_TIME_DIFF}
    fi

    echo "Result: $i" >> clone-results
    echo "GitHub start :"$(getDateFromTimestamp $GITHUB_START_TIME) >> clone-results
    echo "Github end   :"$(getDateFromTimestamp $GITHUB_END_TIME) >> clone-results
    echo "Github time  : ${GITHUB_MINUTES_DIFF}m:${GITHUB_SECONDS_DIFF}s" >> clone-results
    echo "VSTS start   :"$(getDateFromTimestamp $VSTS_START_TIME) >> clone-results
    echo "VSTS end     :"$(getDateFromTimestamp $VSTS_END_TIME) >> clone-results
    echo "VSTS time    : ${VSTS_MINUTES_DIFF}m:${VSTS_SECONDS_DIFF}s" >> clone-results
    echo "==============================" >> clone-results

    # cleanup
    rm -rf che-core
done

echo "GitHub max time    : ${GITHUB_MAX_TIME}" >> clone-results
echo "GitHub min time    : ${GITHUB_MIN_TIME}" >> clone-results
echo "GitHub average time: $(( ${GITHUB_TOTAL_TIME} / ${ATTEMPTS} ))" >> clone-results
echo "GitHub calc error  : $(( ( ${GITHUB_MAX_TIME} - ${GITHUB_MIN_TIME} ) / 2 ))" >> clone-results
echo "-------------------------------------"
echo "VSTS max time    : ${VSTS_MAX_TIME}" >> clone-results
echo "VSTS min time    : ${VSTS_MIN_TIME}" >> clone-results
echo "VSTS average time: $(( ${VSTS_TOTAL_TIME} / ${ATTEMPTS} ))" >> clone-results
echo "VSTS calc error  : $(( ( ${VSTS_MAX_TIME} - ${VSTS_MIN_TIME} ) / 2 ))" >> clone-results
