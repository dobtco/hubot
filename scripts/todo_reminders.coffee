IMAGE_URL = "http://f.cl.ly/items/3q1M011Q072S461s3x46/Screenshot_3_20_13_1_48_PM.png"
HUBOT_USER_ID = 542415
ROOM_URL = "43925_hubot@conf.hipchat.com"

request = require 'request'
_ = require 'underscore'
async = require 'async'

module.exports = (robot) ->
  return

  github = require("githubot")(robot)

  getGithubUser = (x) ->
    process.env["HUBOT_GITHUB_USER_#{x.toUpperCase()}"]

  ping = ->
    request "https://api.hipchat.com/v1/users/list?format=json&auth_token=#{process.env['HUBOT_HIPCHAT_API_TOKEN']}", (err, res, body) ->
      allUsers = JSON.parse(body)['users']

      availableUsers = _.filter allUsers, (user) ->
        (user.mention_name != 'sid') &&
        (user.id != HUBOT_USER_ID) &&
        (user.status in ['available', 'away']) &&
        getGithubUser(user.mention_name)

      showIssueFunctions = []

      queryParams =
        assignee: '*'
        labels: 'current'

      for repo in (process.env['HUBOT_GITHUB_TODOS_REPO'] || '').split(',')
        do (repo) =>
          showIssueFunctions.push( (cb) =>
            github.get "repos/#{repo}/issues", queryParams, (data) ->
              cb(null, data)
          )

      async.parallel showIssueFunctions, (err, results) =>
        log("ERROR: #{err}") if err
        allIssues = [].concat.apply([], results)

        for key, user of availableUsers
          do (key, user) ->
            issueCount = _.filter(allIssues, (issue) ->
              issue.assignee.login == getGithubUser(user.mention_name)
            ).length

            if issueCount == 0
              robot.messageRoom ROOM_URL, "No current issues found for @#{user.mention_name}."
              robot.messageRoom ROOM_URL, IMAGE_URL
              console.log "#{user.mention_name} has no issues, ping is not OK!"
            else if issueCount == 1
              console.log "#{user.mention_name} has one current issue, ping is OK!"
            else
              robot.messageRoom ROOM_URL, "http://cl.ly/image/0Z220V0O0i3j/jpeg.jpg"
              robot.messageRoom ROOM_URL, "Wow, such multitask. @#{user.mention_name} has #{issueCount} issues marked as 'current'!"
              console.log "#{user.mention_name} has #{issueCount} issues, ping is not OK!"

  ping()
  setInterval ping, 3600000
