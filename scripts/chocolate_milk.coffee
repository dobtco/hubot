# Description:
#   Chocolate milk boyz
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   None

module.exports = (robot) ->

  robot.hear /chocolate milk/i, (msg) ->
    msg.send "...did you say Chocolate Milk Boyz?"
    msg.send "http://giant.gfycat.com/BlueGrizzledAppaloosa.gif"
