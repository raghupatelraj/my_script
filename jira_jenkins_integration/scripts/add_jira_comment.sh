#!/usr/bin/env bash

set -euxo pipefail

# Function : Update status on github pull request or commit
# $1 = project
# $2 = commit id
# $3 = status
# $4 = context
# $5 = description
# $6 = target url
function add_jira_comment {
	curl -u raghupatelraj:intel \
        -X POST \
        --data '{"body": "PR raised :'$1'"}' \
        -H "Content-Type: application/json" \
        http://10.66.254.80:8081/rest/api/2/issue/OP-4/comment
}

# Fetch the project name
PROJECT_NAME=${GITHUB_PR_URL}
echo ${PROJECT_NAME}

if [ ${GITHUB_PR_URL} != "null" ]; then
	add_jira_comment ${GITHUB_PR_URL}
fi
