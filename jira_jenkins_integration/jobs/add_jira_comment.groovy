job('androidia-jira-comment') {
  description('Add jira comment')
  parameters {
    stringParam('GITHUB_PR_URL', 'null', 'URL of pull request which triggered this build. Empty for daily/weekly builds')

  }
  steps {
    shell(readFileFromWorkspace('scripts/add_jira_comment.sh'))
  }
  publishers {
    // add mailers here if needed
  }
}
