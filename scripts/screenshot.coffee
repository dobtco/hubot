# Commands:
#   hubot screenshot me <url>

_ = require 'underscore'
Nightmare = require 'nightmare'

browsers = [
  {
    "browser": "ie",
    "browser_version": "11.0",
    "os": "Windows",
    "os_version": "7"
  },
  {
    "browser": "ie",
    "browser_version": "10.0",
    "os": "Windows",
    "os_version": "7"
  },
  {
    "browser": "ie",
    "browser_version": "9.0",
    "os": "Windows",
    "os_version": "7"
  },
  {
    "browser": "firefox",
    "browser_version": "30.0",
    "os": "Windows",
    "os_version": "7"
  },
  {
    "browser": "firefox",
    "browser_version": "30.0",
    "os": "OS X",
    "os_version": "Yosemite"
  },
  {
    "browser": "safari",
    "browser_version": "5.1",
    "os": "Windows",
    "os_version": "7"
  },
  {
    "browser": "safari",
    "browser_version": "8.0",
    "os": "OS X",
    "os_version": "Yosemite"
  },
  {
    "browser": "safari",
    "browser_version": "7.0",
    "os": "OS X",
    "os_version": "Mavericks"
  },
  {
    "browser": "Mobile Safari",
    "device": "iPhone 6",
    "os": "ios",
    "os_version": "8.0"
  },
  {
    "browser": "Mobile Safari",
    "device": "iPhone 5S",
    "os": "ios",
    "os_version": "7.0"
  },
  {
    "browser": "Android Browser",
    "device": "Google Nexus 5",
    "os": "android",
    "os_version": "5.0"
  }
]

log = (msg) ->
  console.log "[screenshot] #{msg}"

# doubleUnquote = (x) ->
#   _s.unquote(_s.unquote(x), "'")

screenshot = (url, callback) ->
  nightmare = new Nightmare()

  nightmare.
    goto('https://www.browserstack.com/screenshots').
    type('#user_email_login', process.env.BROWSERSTACK_USER).
    type('#user_password', process.env.BROWSERSTACK_PW).
    click('#user_submit').
    wait().
    goto('https://www.browserstack.com/screenshots').
    wait(500).
    evaluate( (browsers) ->
      $('.version').removeClass('sel')

      for b in browsers
        if b.device
          $("[browser='#{b.browser}'][device='#{b.device}']"+
            "[os='#{b.os}'][os_version='#{b.os_version}']").click()
        else
          $("[browser='#{b.browser}'][browser_version='#{b.browser_version}']"+
            "[os='#{b.os}'][os_version='#{b.os_version}']").click()
    , ( -> ), browsers).
    type('#screenshots', url).
    click('#btnSnapshot').
    wait(5000).
    url( (outUrl) ->
      callback null,
        in: url
        out: outUrl
    ).
    run (err, nightmare) ->
      if err
        callback("Error: #{err}")

module.exports = (robot) ->
  robot.respond /screenshot me (.*)/i, (msg) ->
    msg.send "Hang on, taking screenshots..."

    setTimeout ->
      screenshot msg.match[1].trim(), (err, deets) ->
        if err
          msg.send "Error taking screenshots: #{err}"
        else
          msg.send ":camera: Took screenshots of _#{deets.in}_: #{deets.out}"
    , 0
