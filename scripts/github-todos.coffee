# Description:
#   Manage todos using GitHub issues.
#
# Dependencies:
#   "underscore": "1.3.3"
#   "underscore.string": "2.1.1"
#   "githubot": "0.4.0"
#
# Configuration:
#   HUBOT_GITHUB_TOKEN
#   HUBOT_GITHUB_USER
#   HUBOT_GITHUB_REPO
#   HUBOT_GITHUB_USER_(.*)
#   HUBOT_GITHUB_API
#
# Commands:
#   hubot add task <text> #todos
#   hubot ask <user> to <text> #todos
#   hubot finish <id> #todos
#   hubot move <id> to <done|current|upcoming|shelf> #todos
#   hubot what am i working on #todos
#   hubot what's <user> working on #todos
#   hubot what's next #todos
#   hubot what's next for <user> #todos
#   hubot what's on <user>'s shelf #todos
#   hubot what's on my shelf #todos
#   hubot work on <id> #todos
#   hubot work on <text> #todos
#
# Author:
#   adamjacobbecker

# Todo:
#    alternate syntaxes
#    assign already-existing tasks
#    what did [i|user] finish [in [period of time]]
#    Automatic time tracking w/ comments

_  = require("underscore")
_s = require("underscore.string")

GITHUB_TODOS_REPO_USER = 'dobtco'
GITHUB_TODOS_REPO_NAME = 'dobt'

module.exports = (robot) ->

  log = (msgs...) ->
    console.log(msgs)

  github = require("githubot")(robot)

  getGithubUser = (userName) ->
    log "Getting GitHub username for #{userName}"
    process.env["HUBOT_GITHUB_USER_#{userName.split(' ')[0].toUpperCase()}"]

  getGithubToken = (userName) ->
    log "Getting GitHub token for #{userName}"
    process.env["HUBOT_GITHUB_USER_#{userName.split(' ')[0].toUpperCase()}_TOKEN"]

  doubleUnquote = (x) ->
    _s.unquote(_s.unquote(x), "'")

  addIssue = (msg, taskBody, userName, opts = {}) ->
    sendData =
      title: doubleUnquote(taskBody).replace(/\"/g, '').split('-')[0]
      body: doubleUnquote(taskBody).split('-')[1] || ''
      assignee: getGithubUser(userName)
      labels: [opts.label || 'upcoming']

    if (x = getGithubToken(msg.message.user.name))
      sendData.token = x

    else if opts.footer
      sendData.body += "\n\n(added by #{getGithubUser(msg.message.user.name) || 'unknown user'}. " +
                   "remember, you'll need to bring them in with an @mention.)"

    log "Adding issue", _.omit(sendData, 'token')

    github.post "repos/#{GITHUB_TODOS_REPO_USER}/#{GITHUB_TODOS_REPO_NAME}/issues", sendData, (data) ->
      msg.send "Added issue ##{data.number}: #{data.html_url}"

  moveIssue = (msg, taskId, newLabel, opts = {}) ->
    sendData =
      state: if newLabel in ['done', 'trash'] then 'closed' else 'open'
      labels: [newLabel.toLowerCase()]

    if (x = getGithubToken(msg.message.user.name))
      sendData.token = x

    log "Moving issue", _.omit(sendData, 'token')

    github.patch "repos/#{GITHUB_TODOS_REPO_USER}/#{GITHUB_TODOS_REPO_NAME}/issues/#{taskId}", sendData, (data) ->
      if _.find(data.labels, ((l) -> l.name.toLowerCase() == newLabel.toLowerCase()))
        msg.send "Moved issue ##{data.number} to #{newLabel.toLowerCase()}: #{data.html_url}"

  showIssues = (msg, userName, label) ->
    queryParams =
      assignee: getGithubUser(userName)
      labels: label

    log "Showing issues", queryParams

    github.get "repos/#{GITHUB_TODOS_REPO_USER}/#{GITHUB_TODOS_REPO_NAME}/issues", queryParams, (data) ->
      if _.isEmpty data
          msg.send "No issues found."
      else
        for issue in data
          msg.send "##{issue.number} #{issue.title}: #{issue.html_url}"

  robot.respond /add task (.*)/i, (msg) ->
    addIssue msg, msg.match[1], msg.message.user.name

  robot.respond /work on ([A-Z\'\"][\s\S\d]+)/i, (msg) ->
    addIssue msg, msg.match[1], msg.message.user.name, label: 'current', footer: true

  robot.respond /ask (\S+) to (.*)/i, (msg) ->
    addIssue msg, msg.match[2], msg.match[1], footer: true

  robot.respond /move\s(task\s)?\#?(\d+) to (\S+)/i, (msg) ->
    moveIssue msg, msg.match[2], msg.match[3]

  robot.respond /finish\s(task\s)?\#?(\d+)/i, (msg) ->
    moveIssue msg, msg.match[2], 'done'

  robot.respond /work on\s(task\s)?\#?(\d+)/i, (msg) ->
    moveIssue msg, msg.match[2], 'current'

  robot.respond /what am i working on\??/i, (msg) ->
    showIssues msg, msg.message.user.name, 'current'

  robot.respond /what(\'s)?(\sis)? (\S+) working on\??/i, (msg) ->
    showIssues msg, msg.match[3], 'current'

  robot.respond /what(\'s)?(\sis)? next for (\S+)\??/i, (msg) ->
    showIssues msg, msg.match[3].replace('?', ''), 'upcoming'

  robot.respond /what(\'s)?(\sis)? next\??(\s*)$/i, (msg) ->
    showIssues msg, msg.message.user.name, 'upcoming'

  robot.respond /what(\'s)?(\sis)? on my shelf\??/i, (msg) ->
    showIssues msg, msg.message.user.name, 'shelf'

  robot.respond /what(\'s)?(\sis)? on (\S+) shelf\??/i, (msg) ->
    showIssues msg, msg.match[3].split('\'')[0], 'shelf'
