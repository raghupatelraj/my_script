import os
import sys
import re
import string
import requests
import json
from bs4 import BeautifulSoup
#print requests.__version__

GITHUB_PR_URL = 'https://github.com/raghupatelraj/jira_test/pull/5'

#Fetch the pull request page details from the environment variable GITHUB_PR_URL
page = requests.get(GITHUB_PR_URL)
soup = BeautifulSoup(page.text, 'html.parser')

#Fetch all commit message with commit-id under PR raised
data = soup.findAll("a", {"class": "message"})

#Function to add github comment
def github_comment(com_det, pr_commit_id, extra_info):
        #Step 1 : Fetch the username,project_name and PR number from the environment variable GITHUB_PR_URL
        GITHUB_PR_URL = 'https://github.com/raghupatelraj/jira_test/pull/5'
        pr_url_split = GITHUB_PR_URL.split('/')
        pr_user = pr_url_split[3]
        pr_project = pr_url_split[4]
        pr_num = pr_url_split[6]

        #Step 2 : Prepare the url to send a POST request
        url = "https://api.github.com/repos/{}/{}/issues/{}/comments?access_token=8b28c6031711f04ef9fa7858b8f40aef472abcf3".format(pr_user,pr_project,pr_num)

        #Step 3 : Prepare data content for comment and dumps into string
        data = json.dumps({"body": "{} {} {}".format(com_det,pr_commit_id, extra_info)})
        headers = {'content-type': 'application/json'}

        #Step 4 : Add the comment
        r = requests.post(url, data, auth=('user', 'pass'))
        print r.status_code
        if (r.status_code == 201):
                print "Comment added to github successfully"
        else:
                print "Errors occurred while adding comment to github"

#Function to add Jira comment
def jira_comment(jira_issue_no):
        #Step 1 : Fetch the username,project_name and PR number from the environment variable GITHUB_PR_URL

        #Step 2 : Prepare the url to send a POST request
        url = "https://01.org/jira/rest/api/2/issue/{}/comment".format(jira_issue_no)
        jcom_det = "PR raised {}".format(GITHUB_PR_URL)
        #Step 3 : Prepare data content for comment and dumps into string
        data = json.dumps({"body": "{}".format(jcom_det)})
        headers = {'content-type': 'application/json'}

        #Step 4 : Add the comment
        r = requests.post(url, data)
        print r.status_code
        if (r.status_code == 201):
                print "Comment added to Jira successfully"
        else:
                print "Errors occurred while adding comment to Jira"

#Check commit-message for all commits under PR raised
for a in data:
        succ = " "
        fail = "please refer to given wiki link for valid commit message: https://github.com/android-ia/manifest/wiki/Contributions"
        comm_message_uni = a['title']
        comm_message = comm_message_uni.encode('ascii','ignore')
        pr_commit = a['href']
        pr_commit_split = pr_commit.split('/')
        pr_commit_id = pr_commit_split[6]
        cm = comm_message.strip('\n').split('\n')
        while '' in cm:
                cm.remove('')
        com_len = len(cm)
        jj = tt = ss = False
        for item in cm:
                if 'Jira:' in item:
                        jira_value = item.split(':')
                        jira_issue_id = jira_value[1]
                        #Check if Jira contain None value.
                        if 'None' in jira_issue_id:
                                print "Jira is created with None value"
                        else:
                                jira_comment(jira_issue_id)

                        jj = True
                        break
        for item in cm:
                if 'Test:' in item:
                        tt = True
                        break
        for item in cm:
                if 'Signed-off-by:' in item:
                        ss = True
                        break
        if jj and tt and ss:
                print "looking good"
                #github_comment("Good to go...patch format is valid for:",pr_commit_id, succ)
        else:
                print "no no no"
                #github_comment("Oh bad...patch format is invalid for:",pr_commit_id, fail)

