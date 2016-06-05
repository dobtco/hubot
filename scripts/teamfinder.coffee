# Configuration:
#   TEAMFINDER_API_TOKEN
#   HUBOT_GITHUB_USER_$SLACKNAME=$GITHUB_USER
#
# Commands:
#   hubot location at our Oakland HQ #teamfinder
#   hubot where is everyone?
#   hubot where is <user>?
#
# License:
#   MIT

_  = require 'underscore'
request = require 'request'

githubUsers = {}
baseUrl = "https://teamfinder.dobt.co/api/"
tokenQuery = { token: process.env['TEAMFINDER_API_TOKEN'] }

getGithubUser = (userName) ->
  githubUsers[userName.split(' ')[0].toUpperCase()]

for k, v of process.env
  if (x = k.match(/^HUBOT_GITHUB_USER_(\S+)$/)?[1])
    githubUsers[x] = v unless x.match(/hubot/i) or x.match(/token/i) or (v in _.values(githubUsers))

locationText = (userName, jsonBody) ->
  if jsonBody
    "#{userName} is #{jsonBody.location.name || 'in an unknown location'} (Updated #{jsonBody.time_ago} ago)"

module.exports = (robot) ->
  robot.respond /where is (\S+)/i, (msg) ->
    return if msg.match[1].toLowerCase() == 'everyone'

    ghUser = if _.values(githubUsers).indexOf(msg.match[1]) > -1
               msg.match[1]
             else
               getGithubUser(msg.match[1])

    if !ghUser
      return msg.send("I don't recognize that name.")

    request { url: baseUrl + 'status', qs: tokenQuery }, (_, res, body) ->
      if res.statusCode != 200
        return msg.send("Error: #{body}")

      if (locText = locationText(msg.match[1], JSON.parse(body)[ghUser]))
        msg.send(locText)
      else
        msg.send "Can't find #{msg.match[1]}."

  robot.respond /where is everyone/i, (msg) ->
    request { url: baseUrl + 'status', qs: tokenQuery }, (_, res, body) ->
      if res.statusCode != 200
        return msg.send("Error: #{body}")

      locText = []
      for k, v of JSON.parse(body)
        locText.push locationText(k, v)

      msg.send(locText.join("\n"))

  robot.respond /location (.*)/i, (msg) ->
    request {
      url: baseUrl + 'update_location_name_by_user',
      method: 'post'
      qs: _.extend(
        { user: getGithubUser(msg.message.user.name), name: msg.match[1] },
        tokenQuery
      )
    }, (_, res, body) ->
      if res.statusCode == 200
        msg.send("Done! Thanks for naming your location.")
      else
        msg.send("Error: #{body}")
