#!/usr/bin/env bash

#set -euxo pipefail

# Function : Update status on github pull request or commit
# $1 = project
# $2 = commit id
# $3 = status
# $4 = context
# $5 = description
# $6 = target url

#Add jira comment when jira issue is created
function add_jira_comment {
	curl -u aiaopenci:openci@intel \
        -X POST \
        --data '{"body": "PR raised :'$1'"}' \
        -H "Content-Type: application/json" \
        https://01.org/jira/rest/api/2/issue/$2/comment

	echo "##################### Jira comment added"
}

#Add comment to github if patch format is invalid
function add_github_comment {
	curl "https://api.github.com/repos/$1/$2/issues/$3/comments?access_token=xxxxxx" \
        -H "Content-Type: application/json" \
        -X POST \
	-d "{\"body\":\"$4 $5 $6\"}"
	
	echo "##################### Github comment added"
}

#check patch format 
function add_comments {
        #Fetch the patch to check Jira, Test and Signed-off.
        JIRA_ISSUE_ID=`wget -q -O - "$@" $1.patch | grep -i Jira: | cut -d'/' -f5 | cut -d':' -f2 | head -1`
        Test=`wget -q -O - "$@" $1.patch | grep -i Test: | head -1`
        signed_off=`wget -q -O - "$@" $1.patch | grep -i Signed-off | head -1`
	    patch_fail_1="Commit message is invalid for commit id:"
        patch_fail_2="<br>Commit message should be as below: <br><br>Jira: Link to Jira [Default:None.]<br>Test: What tests are expected to pass <br>Signed-off-by: <Author/Contributor><br><br>For more details please refer to below wiki link: https://github.com/android-ia/manifest/wiki/Contributions"
        patch_success="Commit message is verified for commit id:"
        thank_you="<br> "
        #Check patch format than Add jira comment.
        if [[ -n "$JIRA_ISSUE_ID" && "$Test" && "$signed_off" ]]; then
		add_github_comment ${github_user_name} ${github_repo_name} ${github_pull_number} "$patch_success" "$1" "$thank_you"
                if [[ ${JIRA_ISSUE_ID} =~ None ]]; then
                        echo "***Jira is created with None value***"
                else
                        if  [ "${GITHUB_PR_URL} != "null" " ] && [ "${JIRA_ISSUE_ID} != "null" " ]; then
                                add_jira_comment ${GITHUB_PR_URL} ${JIRA_ISSUE_ID} 
                        fi
                fi
        else
                add_github_comment ${github_user_name} ${github_repo_name} ${github_pull_number} "$patch_fail_1" "$1" "$patch_fail_2"
                echo "********************Invalid patch format************************"

        fi
}



# Fetch the project name
PROJECT_NAME=${GITHUB_PR_URL}

# Fetch the user_name, repo_name and pull_number.
github_user_name="`echo ${GITHUB_PR_URL} | grep / | cut -d/ -f4`"
github_repo_name="`echo ${GITHUB_PR_URL} | grep / | cut -d/ -f5`"
github_pull_number="`echo ${GITHUB_PR_URL} | grep / | cut -d/ -f7`"

#find the no. of commits in PR
no_of_commit=`wget -q -O - "$@" ${GITHUB_PR_URL}.patch | grep 'From ' | wc -l`
t=$no_of_commit

#check patch format and add commets to jira/github depends on patch format.
for i in $(seq 1 $t)
do
        commit_id=`wget -q -O - "$@" https://github.com/raghupatelraj/jira_test/pull/5.patch | grep 'From ' | cut -d' ' -f2 | head -$i | tail -1`
        GITHUB_commit_URL=${GITHUB_PR_URL}"/commits/"$commit_id
        add_comments ${GITHUB_commit_URL}
done

