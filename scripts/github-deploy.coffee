# Commands:
#   hubot deploy <repo> immediately #deploy
#   hubot deploy <repo> tonight #deploy
#   hubot don't deploy <repo> tonight #deploy
#   hubot list tonight's deploys #deploy

_ = require 'underscore'
CronJob = require('cron').CronJob
require 'time'

module.exports = (robot) ->

  robot.brain.data.deploys ||= []
  github = require("githubot")

  addDeploy = (repoName) ->
    robot.brain.data.deploys.push(repoName)
    robot.brain.data.deploys = _.uniq(robot.brain.data.deploys)

  removeDeploy = (repoName) ->
    robot.brain.data.deploys = _.without(robot.brain.data.deploys, repoName)

  listDeploys = (msg) ->
    deployism = _.sample([
      'getting freaky'
      'taking the crazy train to deploy-town'
      "deeeployin'"
      'pushing out some hot new code'
      ':ship:ing'
      "gonna :shipit: like it's hot"
    ])

    if robot.brain.data.deploys.length > 0
      msg.send "Tonight we're #{deployism} at 10pm Eastern: #{robot.brain.data.deploys.join(', ')}"
    else
      msg.send "No deploys scheduled for tonight"

  log = (msgs...) ->
    console.log(msgs)

  getGithubToken = (userName) ->
    log "Getting GitHub token for #{userName}"
    process.env["HUBOT_GITHUB_USER_#{userName.split(' ')[0].toUpperCase()}_TOKEN"]

  mergeToProduction = (msg, repoName) ->
    options = {}

    if msg.message && (x = getGithubToken(msg.message.user.name))
      options.token = x
    else
      msg.send "Couldn't find GitHub token for #{msg.message.user.name}.\n \
        Is #{"HUBOT_GITHUB_USER_#{msg.message.user.name.split(' ')[0].toUpperCase()}_TOKEN"} set?"
      return

    client = github(robot, options)

    client.handleErrors (response) ->
      msg.send "An error occurred: #{response.error}. Raw response:\n>#{response.body}"

    client.post "repos/dobtco/#{repoName}/pulls",
      title: 'Deploy to production'
      head: 'master'
      base: 'production'
    , (data) ->

      msg.send "Pull request ##{data.number} created: #{data.html_url}"
      setTimeout ->
        msg.send "Merging..."

        setTimeout ->
          client.put "repos/dobtco/#{repoName}/pulls/#{data.number}/merge",
            commit_message: 'Deploy to production'
          , (mergeData) ->
            msg.send "Successfully merged. Tests will run and this ref will be pushed to production."
        , 1000

      , 200

  robot.respond /deploy (.*) immediately/i, (msg) ->
    mergeToProduction msg, msg.match[1]

  robot.respond /deploy (.*) tonight/i, (msg) ->
    addDeploy(msg.match[1])
    msg.send "I'll deploy #{msg.match[1]} tonight unless I'm told otherwise."
    listDeploys(msg)

  robot.respond /don't deploy (.*) tonight/i, (msg) ->
    removeDeploy(msg.match[1])
    msg.send "Removing #{msg.match[1]} from tonight's deploys."
    listDeploys(msg)

  robot.respond /list tonight's deploys/i, (msg) ->
    listDeploys(msg)

  new CronJob '0 22 * * *', ->
    return unless robot.brain.data.deploys.length > 0
    robot.messageRoom '#dev', "Deploying #{robot.brain.data.deploys.length} app(s)"

    msg =
      send: (x) ->
        robot.messageRoom '#dev', x

    for i in robot.brain.data.deploys
      mergeToProduction(msg, i)

    robot.brain.data.deploys = []
    robot.messageRoom '#dev', "Deploys done!"

  , null, true, "America/New_York"
