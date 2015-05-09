# Description:
#   Access the jservice.io API for trivia.
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot trivia                        - returns a random trivia question
#   hubot trivia answer (your answer)   - checks your answer to the trivia question
#   hubot trivia what is (your answer)  - checks your answer to the trivia question
#   hubot trivia solution               - returns the answer trivia question
#
# Author:
#   maxbeizer

class Trivia
  constructor: (@robot) ->
    @data = {}

  init: (data) ->
    capitalizedTitle = @capitalize(data[0].category.title)
    @data.question = data[0].question
    @data.category = capitalizedTitle
    @data.answer = data[0].answer.replace(/(<([^>]+)>)/ig,"")

  fuzzyMatch: (haystack, needle) ->
    i = 0
    n = -1
    l = null
    while l = needle[i++]
      return false  unless ~(n = haystack.indexOf(l, n + 1))
    true

  clearQuestion: ->
    @data = {}

  capitalize: (string) ->
    result = string.replace /\w\S*/g, (txt) ->
      txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()

    result

module.exports = (robot) ->
  trivia = new Trivia(robot)

  okResponses = [
    "I'll allow it",
    "A wink's as good as a nod to a blind man",
    'Close enough'
  ]

  positiveResponses = [
    'Bazinga',
    'On the money',
    'You are the shining light of the world',
    'Way to get the easy ones',
    'Boomshakalaka',
    'A thing of beauty is a joy forever. Nice answer'
  ]

  negativeResponses = [
    'Not so much',
    'No luck there',
    'No',
    'Incorrect',
    'Wrong'
  ]

  robot.respond /(trivia|trivia me)/i, (msg) ->
    msg.http("http://jservice.io/api/random")
      .get() (err, res, body) ->
        data = JSON.parse(body)
        trivia.init(data)
        return msg.send "!trivia" unless trivia.data.question?
        msg.send "Category: #{trivia.data.category}"
        setTimeout () ->
          msg.send "Question: #{trivia.data.question}"
        , 500

  robot.respond /solution/i, (msg) ->
    return msg.send 'Ask another question, please' unless trivia.data.answer?
    msg.send "Answer: #{trivia.data.answer}"
    trivia.clearQuestion()

  robot.respond /(answer|what is) (.*)/i, (msg) ->
    return msg.send 'Ask another question, please' unless trivia.data.answer?
    lowerCasedAnswer = trivia.data.answer.toLowerCase()
    lowerCasedResponse = msg.match[2].toLowerCase()
    user = msg.message.user.name

    return msg.send "No Cheating, #{user}" if lowerCasedResponse.length == 1

    if lowerCasedAnswer == lowerCasedResponse
      msg.send "#{msg.random positiveResponses}, #{user}!"
      trivia.clearQuestion()
    else if trivia.fuzzyMatch(lowerCasedAnswer, lowerCasedResponse)
      msg.send "#{msg.random okResponses}, #{user}."
      msg.send "Answer: #{trivia.data.answer}"
      trivia.clearQuestion()
    else
      msg.send "#{msg.random(negativeResponses)}, #{user}"
