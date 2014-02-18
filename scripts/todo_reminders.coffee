IMAGE_URL = "http://f.cl.ly/items/3q1M011Q072S461s3x46/Screenshot_3_20_13_1_48_PM.png"
HUBOT_USER_ID = 542415

request = require 'request'
_ = require 'underscore'

module.exports = (robot) ->

  github = require("githubot")(robot)

  getGithubUser = (x) ->
    process.env["HUBOT_GITHUB_USER_#{x.toUpperCase()}"]

  ping = ->
    request "https://api.hipchat.com/v1/users/list?format=json&auth_token=#{process.env['HUBOT_HIPCHAT_API_TOKEN']}", (err, res, body) ->
      allUsers = JSON.parse(body)['users']

      availableUsers = _.filter allUsers, (user) ->
        (user.id != HUBOT_USER_ID) &&
        (user.status in ['available', 'away']) &&
        getGithubUser(user.mention_name)

      for key, user of availableUsers
        github.get "repos/#{process.env['HUBOT_GITHUB_TODOS_REPO']}/issues",
          assignee: getGithubUser(user.mention_name)
          labels: 'current'
        , (data) ->
          if _.isEmpty data
            robot.messageRoom 'Hubot', "No current issues found for @#{user.mention_name}."
            robot.messageRoom 'Hubot', IMAGE_URL
            console.log "#{user.mention_name} has no issues, ping is not OK!"
          else
            console.log "#{user.mention_name} has issues, ping is OK!"

  ping()
  setInterval ping, 3600000
