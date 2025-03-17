#!/usr/bin/env python

import requests
import os
import json

#
# This script automatically adds reviewers on the Github PR page
# It fetches the domain owners from the metadata.json file and then
# adds those reviewers on the PR page by sending a POST request to
# Github API V3
# Reference : https://developer.github.com/v3/pulls/review_requests/#create-a-review-request
#
projects = {
        "android-ia/DPTF":["bbian"]
}

print('*'*30,"Adding Reviewers","*"*30)

#Step 1 : Fetch the pull request page details from the environment variable GITHUB_PR_URL
pr_url = os.environ['GITHUB_PR_URL']
pr_url_split = pr_url.split('/')
pr_user = pr_url_split[3]
pr_project = pr_url_split[4]
pr_num = pr_url_split[6]

#Step 2 : Prepare the url to send a POST request
url = "https://api.github.com/repos/{}/{}/pulls/{}/requested_reviewers?access_token=xxxxx".format(pr_user,pr_project,pr_num)

#Step 3 : Fetch the reviewers for the 'project'
reviewers = projects.get(pr_user+'/'+pr_project,[])
try:
    reviewers.remove(pr_user)
except ValueError:
    pass #do nothing

print("Adding the following users as reviewers : {}".format(reviewers))
PARAMS = {'reviewers': reviewers}

#Step 4 : Add the reviewers
r = requests.post(url=url,json=PARAMS)
if r.status_code == 201:
    print("Added reviewers successfully")
else:
    print("FAILED!!! Status code : ",r.status_code)
