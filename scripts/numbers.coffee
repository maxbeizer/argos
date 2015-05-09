# Description:
#   Access the numbersapi.com API for fun facts.
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot number    - returns a fact about random number
#   hubot number n  - returns a fact about number n
#
# Author:
#   maxbeizer

module.exports = (robot) ->
  robot.respond /number\s(\d+)|number/i, (msg) ->
    num = msg.match[1] or 'random'
    msg.http("http://numbersapi.com/#{num}?notfound=floor")
      .get() (err, res, body) ->
        msg.send "#{body} - numbersapi.com"
