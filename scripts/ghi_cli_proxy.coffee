# Description:
#   Github Issues CLI Proxy

sys = require('sys')
exec = require('child_process').exec

getToken = (msg) ->
  process.env["HUBOT_GITHUB_USER_#{msg.message.user.name.split(' ')[0].toUpperCase()}_TOKEN"]

module.exports = (robot) ->
  robot.respond /ghi (\S+) (.*)/i, (msg) ->
    return if msg.match[1].match /^use/

    exec "git config ghi.token #{getToken(msg)}"
    exec "git config ghi.repo dobtco/#{msg.match[1]}"
    exec "ghi #{msg.match[2]}", (error, stdout, stderr) ->
      msg.send(stdout)
      console.log(error) if error
