# Description:
#   Github Issues CLI Proxy

sys = require('sys')
exec = require('child_process').exec

getToken = (msg) ->
  process.env["HUBOT_GITHUB_USER_#{msg.message.user.name.split(' ')[0].toUpperCase()}_TOKEN"]

getName = (msg) ->
  process.env["HUBOT_GITHUB_USER_#{msg.message.user.name.split(' ')[0].toUpperCase()}"]

module.exports = (robot) ->
  robot.respond /ghi (\S+) (.*)/i, (msg) ->
    putter = (error, stdout, stderr) ->
      msg.send(stdout)
      console.log(error) if error

    exec "git config github.user #{getName(msg)}", putter
    exec "git config ghi.token #{getToken(msg)}", putter
    exec "git config ghi.repo dobtco/#{msg.match[1]}",  putter
    exec "ghi #{msg.match[2]}", putter
