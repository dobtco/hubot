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

nameFromGhUser = (ghUser) ->
  for k, v of githubUsers
    return k if ghUser == v

for k, v of process.env
  if (x = k.match(/^HUBOT_GITHUB_USER_(\S+)$/)?[1])
    githubUsers[x] = v unless x.match(/hubot/i) or x.match(/token/i) or (v in _.values(githubUsers))

locationText = (userName, jsonBody) ->
  if jsonBody
    "#{userName} is #{jsonBody.location.name || 'in an unknown location'} (Updated #{jsonBody.time_ago} ago)"

module.exports = (robot) ->
  locKey = (user, locId) ->
    "#{user}-#{locId}-v4"

  alreadyAskedAboutLocation = (user, locId) ->
    !!robot.brain.data.teamfinderAsks?[locKey(user, locId)]

  trackAsk = (user, locId) ->
    robot.brain.data.teamfinderAsks || = {}
    robot.brain.data.teamfinderAsks[locKey(user, locId)] = true

  checkForUnknownLocations = ->
    request { url: baseUrl + 'status', qs: tokenQuery }, (err, res, body) ->
      locs = JSON.parse(body)
      for k, v of locs
        unless v.location.name || alreadyAskedAboutLocation(k, v.location.id)
          console.log 'messageroom', nameFromGhUser(k).toLowerCase()
          robot.messageRoom(
            nameFromGhUser(k).toLowerCase(),
            "You're currently in an unknown location.\n(Say \"location at the Oakland HQ\" to set your location name)"
          )

          trackAsk(k, v.location.id)

  checkForUnknownLocations()
  setInterval checkForUnknownLocations, 1000 * 60 * 2 # every two minutes

  robot.respond /where is (\S+)/i, (msg) ->
    return if msg.match[1].toLowerCase() == 'everyone'

    ghUser = if _.values(githubUsers).indexOf(msg.match[1]) > -1
               msg.match[1]
             else
               getGithubUser(msg.match[1])

    if !ghUser
      return msg.send("I don't recognize that name.")

    request { url: baseUrl + 'status', qs: tokenQuery }, (err, res, body) ->
      if res.statusCode != 200
        return msg.send("Error: #{body}")

      if (locText = locationText(msg.match[1], JSON.parse(body)[ghUser]))
        msg.send(locText)
      else
        msg.send "Can't find #{msg.match[1]}."

  robot.respond /where is everyone/i, (msg) ->
    request { url: baseUrl + 'status', qs: tokenQuery }, (err, res, body) ->
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
    }, (err, res, body) ->
      if res.statusCode == 200
        msg.send("Done! Thanks for naming your location.")
      else
        msg.send("Error: #{body}")
