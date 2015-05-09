# Description:
#   Get the word of the day
#
# Dependencies:
#   xml2js
#
# Configuration:
#
#
# Commands:
#   hubot wotd
#
# Author:
#   maxbeizer
#

xml2js = require 'xml2js'
parser = new xml2js.Parser()

class WOTD
  constructor: (@data) ->


  getDescription: =>
    @data['rss']['channel'][0]['item'][0]['description']


  buildDisplayString: =>
    "#{@getDescription()} -- dictionary.com"


module.exports = (robot) ->
  robot.respond /wotd/i, (msg) ->
    msg.http('http://dictionary.reference.com/wordoftheday/wotd.rss')
      .get() (err, res, body) ->
        parser.parseString body, (err, result) ->
          return msg.send "Oops! There was an error: #{err}" if err?

          wotd = new WOTD result
          msg.send wotd.buildDisplayString()
