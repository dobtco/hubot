# Commands:
#   hubot deploy <repo> to production #deploy

module.exports = (robot) ->

  log = (msgs...) ->
    console.log(msgs)

  github = require("githubot")(robot)

  getGithubToken = (userName) ->
    log "Getting GitHub token for #{userName}"
    process.env["HUBOT_GITHUB_USER_#{userName.split(' ')[0].toUpperCase()}_TOKEN"]

  robot.respond /deploy (.*) to production/i, (msg) ->

    options = {}

    if (x = getGithubToken(msg.message.user.name))
      options.token = x

    github.handleErrors (response) ->
      msg.send response.error
      msg.send response.body

    github.withOptions(options).post "repos/dobtco/#{msg.match[1]}/pulls",
      title: 'Deploy to production'
      head: 'master'
      base: 'production'
    , (data) ->

      msg.send "Pull request ##{data.number} created: #{data.html_url}"
      msg.send "Merging..."

      github.withOptions(options).put "repos/dobtco/#{msg.match[1]}/pulls/#{data.number}/merge",
        commit_message: 'Deploy to production'
      , (mergeData) ->
        msg.send "Successfully merged. Tests will run and this ref will be pushed to production."
