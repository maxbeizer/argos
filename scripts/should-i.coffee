# Description:
#   hubot gives you sage advice
#
# Examples:
#   hubot: should I <first_thing> or <second_thing>?
#
# Author:
#   maxbeizer

directives = [
  "You should go with",
  "The obvious choice is",
  "Only a fool would choose",
  "Roll Tide! Surely",
  "I may be all hopped up on goofballs, but I'm pretty sure you should",
  "Do you even lift? Go with",
  "Are you mental? It's"
]

epithets = [
  "bro.",
  "chief.",
  "boyeeeee.",
  "champ.",
  "DO YOU EVEN LIFT?!!?!",
  "boss.",
  "amigo mio.",
  "hoss.",
  "homie."
]

person_shifts = [
  [/\sme\b/ig, " $you"],
  [/\smine\b/ig, " $yours"],
  [/\smy\b/ig, " $your"],
  [/\syou\b/ig, " me"],
  [/\syour\b/ig, " my"],
  [/\syours\b/ig, " mine"],
  [/\$/ig, ""]
]

module.exports = (robot) ->
  robot.respond /\s+should\s+I\s+(.*)\s+or\s+(.*)\?$/i, (msg) ->
    msg.match.shift()
    ary = msg.match.map (elm) ->
      subPronouns(elm.trim())
    directive = msg.random directives
    epithet = msg.random epithets
    response = msg.random ary
    msg.send "#{directive} #{response}, #{epithet}"

subPronouns = (phrase) ->
  person_shifts.reduce((acc, pattern) ->
    acc.replace.apply acc, pattern
  , phrase)
