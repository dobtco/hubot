# Configuration:
#   SENDGRID_API_KEY
#
# Commands:
#   hubot sendgrid logs for <email> #sendgrid

sg  = require('sendgrid').SendGrid(process.env.SENDGRID_API_KEY)
rightpad = require('right-pad')
_ = require('underscore')
moment = require('moment')

module.exports = (robot) ->
  padLength = (items, key) ->
    lengths = _.map items, (item) ->
      item[key].length

    (_.max(lengths) || 0) + 3

  robot.respond /sendgrid logs for (.*)/i, (msg) ->
    request = sg.emptyRequest()
    request.method = 'GET'
    request.path = '/v3/email_activity'
    query = msg.match[1].trim()
    request.queryParams['email'] = query
    request.queryParams['limit'] = 10

    sg.API request, (res) ->
      if res.statusCode != 200
        msg.send('Sorry, an error occured when fetching logs from SendGrid.')
        return

      items = JSON.parse(res.body)
      msgToSay = ''

      msgToSay += "Found #{if items.length == 10 then '10+' else items.length} #{if items.length == 1 then 'log' else 'logs'} for #{query}."

      if items.length > 0
        msgToSay += "\n\n"

      for item in items
        paddedEvent = rightpad("[#{item.event}]", padLength(items, 'event'))
        reason = if item.reason then "(#{item.reason})"
        time = moment.unix(item.created).fromNow()
        msgToSay += "#{paddedEvent} #{rightpad(item.email, padLength(items, 'email'))} #{rightpad(time, 15)} #{reason || ''}\n"

      msg.send(msgToSay)
