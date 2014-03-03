IMAGE_URL = "http://f.cl.ly/items/3q1M011Q072S461s3x46/Screenshot_3_20_13_1_48_PM.png"
HUBOT_USER_ID = 542415
ROOM_URL = "43925_hubot@conf.hipchat.com"

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
        do (key, user) ->
          github.get "repos/#{process.env['HUBOT_GITHUB_TODOS_REPO']}/issues",
            assignee: getGithubUser(user.mention_name)
            labels: 'current'
          , (data) ->
            if _.isEmpty data
              robot.messageRoom ROOM_URL, "No current issues found for @#{user.mention_name}."
              robot.messageRoom ROOM_URL, IMAGE_URL
              console.log "#{user.mention_name} has no issues, ping is not OK!"
            else if data.length == 1
              console.log "#{user.mention_name} has one current issue, ping is OK!"
            else
              robot.messageRoom ROOM_URL, "Wow, such multitask. @#{user.mention_name} has #{data.length} issues marked as 'current'!"
              console.log "#{user.mention_name} has #{data.length} issues, ping is not OK!"

  ping()
  setInterval ping, 3600000
