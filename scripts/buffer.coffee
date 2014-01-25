# Description:
#   Hubot interface for Buffer.
#
# Dependencies:
#   "underscore"
#   "underscore.string"
#
# Configuration:
#   HUBOT_BUFFER_TOKEN
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

# Todo:
#

_ = require('underscore')
_s = require('underscore.string')
request = require('request')

PROFILES =
  'twitter': '518bd196e19492301400001b'
  'facebook': '518bd1b1e19492581400001a'
  'google': '52e3ed6d0a0e32687a0001bb'
  'linkedin': '52e40810d35725656e000226'

# Aliases
PROFILES['gplus'] = PROFILES['google+'] = PROFILES['google']
PROFILES['tweet'] = PROFILES['twitter']
PROFILES['fb'] = PROFILES['facebook']

SERVICES_REGEX = "(twitter|tweet|fb|facebook|google|linkedin|gplus|google\\+)"

API_ROOT = "https://api.bufferapp.com/1"

atp = "access_token=#{process.env['HUBOT_BUFFER_TOKEN']}"

module.exports = (robot) ->

  log = (msgs...) ->
    console.log(msgs)

  doubleUnquote = (x) ->
    _s.unquote(_s.unquote(x), "'")

  getServiceId = (x) ->
    PROFILES[x.toLowerCase()]

  sendUpdate = (msg, opts = {}) ->
    opts = _.extend
      service: 'all'
      text: ''
      immediate: false
    , opts

    opts.sendData =
      text: doubleUnquote(opts.text)
      "profile_ids": (if opts.service == 'all' then _.uniq(_.values(PROFILES)) else [getServiceId(opts.service)])

    log 'sendUpdate', opts

    request.post "#{API_ROOT}/updates/create.json?#{atp}", { form: opts.sendData }, (err, res, body) ->
      data = JSON.parse(body)
      msg.send 'Error' unless data.success
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

  robot.respond new RegExp("show (me\s)?(my\s)?#{SERVICES_REGEX} buffer", 'i'), (msg) ->
    listUpdates msg, service: msg.match[3]

  robot.respond new RegExp("show (me\s)?(my\s)?sent #{SERVICES_REGEX} buffer", 'i'), (msg) ->
    listUpdates msg, pendingOrSent: 'sent', service: msg.match[3]
