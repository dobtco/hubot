# Description:
#   Displays our current DUNS number or SAM.gov registration
#
# Configuration:
#   You'll need to set HUBOT_GOV_API_TOKEN as an environmental variable.
#   To get an token, head over to https://api.data.gov/signup/.
#   You just need a name/email combo as it's solely used for rate limiting.
#
# Commands:
#   hubot samdotgov me - display's your current Sam.gov registration
#   hubot duns me - display's your DUNS registration number

prettyjson = require('prettyjson');

DUNS_NUMBER = "079100078"
API_BASE = "https://api.data.gov/sam/v1/registrations"

module.exports = (robot) ->
  robot.respond /samdotgov me$/i, (msg) ->
    token = process.env.HUBOT_GOV_API_TOKEN || ""
    msg.http("#{API_BASE}/#{DUNS_NUMBER}0000?api_key=#{token}").get() (err, res, body) ->
      if err
        robot.emit 'error', err, msg
      else
        try
          data = JSON.parse(body).sam_data.registration
          msg.send prettyjson.render(data, {
            noColor: true
          })
        catch e
          robot.emit 'error', e, msg

  robot.respond /duns me$/i, (msg) ->
    msg.send "Our DUNS number is #{DUNS_NUMBER}, duh."
