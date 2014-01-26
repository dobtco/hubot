# Description:
#   Hubot interface for Buffer.
#
# Dependencies:
#   "underscore": "1.5.2"
#   "underscore.string": "2.3.3"
#   "request": "2.33.0"
#
# Configuration:
#   HUBOT_BUFFER_TOKEN
#   HUBOT_BUFFER_FACEBOOK
#   HUBOT_BUFFER_LINKEDIN
#   HUBOT_BUFFER_GOOGLE
#   HUBOT_BUFFER_TWITTER
#
# Commands:
#   hubot <service> buffer <text> #buffer
#   hubot buffer <text> #buffer
#   hubot immediate <service> buffer <text> #buffer
#   hubot immediate buffer <text> #buffer
#   hubot show (me) (my) <service> buffer #buffer
#   hubot show (me) (my) sent <service> buffer(s) #buffer
#
# Author:
#   adamjacobbecker
#
# Notes:
#   HUBOT_BUFFER_TOKEN is your API token. You'll need to create an app in
#   the Buffer dashboard to get this value.
#
#   The rest of the environment variables are your profile IDs, and you're
#   welcome to configure as few or many as you wish. You can get them
#   from the buffer web interface, since your URL will look something like:
#   https://bufferapp.com/app/profile/<PROFILE ID>/buffer
#


_ = require('underscore')
_s = require('underscore.string')
request = require('request')

PROFILES = {}

profile_types = {
  'FACEBOOK': ['FB'],
  'TWITTER': ['TWEET'],
  'GOOGLE': ['GPLUS', 'GOOGLE+'],
  'LINKEDIN': []
}

for k, v of profile_types
  if process.env["HUBOT_BUFFER_#{k}"]
    PROFILES[k] = process.env["HUBOT_BUFFER_#{k}"]
    PROFILES[x] = PROFILES[k] for x in v

SERVICES_REGEX = "(#{_.map(_.keys(PROFILES), ((k) -> k.replace(/([.?*+^$[\]\\(){}|-])/g, "\\$1")) ).join('|')})"

API_ROOT = "https://api.bufferapp.com/1"

atp = "access_token=#{process.env['HUBOT_BUFFER_TOKEN']}"

module.exports = (robot) ->

  log = (msgs...) ->
    console.log(msgs)

  doubleUnquote = (x) ->
    _s.unquote(_s.unquote(x), "'")

  getServiceId = (x) ->
    PROFILES[x.toUpperCase()]

  sendUpdate = (msg, opts = {}) ->
    opts = _.extend
      service: 'all'
      text: ''
      immediate: false
    , opts

    opts.sendData =
      text: doubleUnquote(opts.text)
      "profile_ids": (if opts.service == 'all' then _.uniq(_.values(PROFILES)) else [getServiceId(opts.service)])

    if opts.immediate
      opts.sendData.now = true

    log 'sendUpdate', opts

    request.post "#{API_ROOT}/updates/create.json?#{atp}", { form: opts.sendData }, (err, res, body) ->
      data = JSON.parse(body)
      msg.send 'Error' unless data.success

      if opts.sendData.now
        msg.send "Posted to #{data.updates.length} account(s): \"#{data.updates[0].text}\""
      else
        msg.send "Buffered to #{data.updates.length} account(s): \"#{data.updates[0].text}\""

  listUpdates = (msg, opts = {}) ->
    opts = _.extend
      service: 'all'
      pendingOrSent: 'pending'
    , opts

    opts.serviceId = getServiceId(opts.service)

    log 'listUpdates', opts

    request.get "#{API_ROOT}/profiles/#{opts.serviceId}/updates/#{opts.pendingOrSent}.json?#{atp}", (err, res, body) ->
      data = JSON.parse(body)

      if data.total == 0
        msg.send "No updates found."
      else
        msg.send "#{data.total} update(s) found."

        for update in data.updates
          msg.send "\"#{update.text}\" - Scheduled for #{update.day} at #{update.due_time}"

  robot.respond /buffer (.*)/i, (msg) ->
    sendUpdate msg, text: msg.match[1]

  robot.respond /immediate buffer (.*)/i, (msg) ->
    sendUpdate msg, text: msg.match[1], immediate: true

  robot.respond new RegExp("#{SERVICES_REGEX} buffer (.*)", 'i'), (msg) ->
    sendUpdate msg, text: msg.match[2], service: msg.match[1]

  robot.respond new RegExp("immediate #{SERVICES_REGEX} buffer (.*)", 'i'), (msg) ->
    sendUpdate msg, text: msg.match[2], service: msg.match[1], immediate: true

  robot.respond new RegExp("show (me\\s)?(my\\s)?#{SERVICES_REGEX} buffer", 'i'), (msg) ->
    listUpdates msg, service: msg.match[3]

  robot.respond new RegExp("show (me\\s)?(my\\s)?sent #{SERVICES_REGEX} buffer", 'i'), (msg) ->
    listUpdates msg, pendingOrSent: 'sent', service: msg.match[3]
