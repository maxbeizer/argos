# Description:
#   Track arbitrary karma
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   <name>++ - give name some karma
#   <name>-- - take away some of name's karma
#   hubot karma <name> - check name's karma (if <name> is omitted, show the top 5)
#   hubot karma empty <name> - empty a name's karma
#   hubot karma best - show the top 5
#   hubot karma worst - show the bottom 5
#   hubot karma all - show all subjects who have received karma
#   hubot karma alias <alias> <name> <confirm> - assign <alias> as an alias to <name> (if alias exists as an existing user, you must pass "true" to confirm)
#   hubot karma unalias <alias> <name> - remove <alias> as an alias from <name>
#   hubot karma aliases <name> - show aliases for <name>
#
# Author:
#   stuartf

class Karma

  constructor: (@robot) ->
    @cache = {}

    @increment_responses = [
      "+1!", "gained a level!", "is on the rise!", "leveled up!"
    ]

    @decrement_responses = [
      "took a hit! Ouch.", "took a dive.", "lost a life.", "lost a level."
    ]

    @robot.brain.on 'loaded', =>
      if @robot.brain.data.karma
        @cache = @robot.brain.data.karma

  kill: (name) ->
    subject = @findOrInitialize(name)
    delete @cache[subject]
    @robot.brain.data.karma = @cache
    return subject

  increment: (name) ->
    subject = @findOrInitialize(name)
    @cache[subject]['karma'] += 1
    @robot.brain.data.karma = @cache
    return subject

  decrement: (name) ->
    subject = @findOrInitialize(name)
    @cache[subject]['karma'] -= 1
    @robot.brain.data.karma = @cache
    return subject

  incrementResponse: ->
    @increment_responses[Math.floor(Math.random() * @increment_responses.length)]

  decrementResponse: ->
    @decrement_responses[Math.floor(Math.random() * @decrement_responses.length)]

  alias: (alias, name) ->
    # Get existing alias info
    alias_karma = @get(alias)
    old_alias = @findByAlias(alias)
    # Alias process
    @kill(alias) # make sure we get rid of the aliased record
    subject = @findOrInitialize(name)
    @cache[subject]['aliases'].push(alias) if @cache[subject]['aliases'].indexOf(alias) == -1
    # Merge back in old aliases
    @cache[subject]['aliases'].push old_alias['aliases'] if old_alias['aliases'].length > 0
    # Updated karma if it existed
    if (alias_karma > 0)
      @cache[subject]['karma'] += alias_karma
    @robot.brain.data.karma = @cache

  unalias: (alias, name) ->
    subject = @findOrInitialize(name)
    @cache[subject]['aliases'].pop(alias) if @cache[subject]['aliases'].indexOf(alias) != -1
    @robot.brain.data.karma = @cache

  aliases: (name) ->
    subject = @findOrInitialize(name)
    @cache[subject]['aliases']

  get: (name) ->
    record = @findByAlias(name)
    record.karma

  findOrInitialize: (name) ->
    # try to access directly
    if @cache[name] then return name

    # look for alias
    for key, item of @cache
      return key if item['aliases']?.indexOf(name) > -1

    # can't find it
    @cache[name] = { karma: 0, aliases: [] }
    return name

  findByAlias: (name) ->
    subject = @findOrInitialize(name)
    return @cache[subject]

  nameOrAliasExists: (name) ->
    # try to access directly
    if @cache[name] then return name

    # look for alias
    for key, item of @cache
      return key if item['aliases']?.indexOf(name) > -1

    return false

  sort: ->
    s = []
    for name, item of @cache
      s.push({ name: name, karma: item.karma })
    s.sort (a, b) -> b.karma - a.karma

  top: (n = 5) ->
    sorted = @sort()
    sorted.slice(0, n)

  bottom: (n = 5) ->
    sorted = @sort()
    sorted.slice(-n).reverse()

module.exports = (robot) ->
  karma = new Karma robot

  robot.hear /(\S+[^+\s])\+\+(\s|$)/, (msg) ->
    subject = msg.match[1].toLowerCase()
    name = karma.increment(subject)
    msg.send "#{name} #{karma.incrementResponse()} (Karma: #{karma.get(name)})"

  robot.hear /(\S+[^-\s])--(\s|$)/, (msg) ->
    subject = msg.match[1].toLowerCase()
    name = karma.decrement(subject)
    msg.send "#{name} #{karma.decrementResponse()} (Karma: #{karma.get(name)})"

  robot.respond /karma alias (\S+[^-\s]) (\S+[^-\s])( true)?$/i, (msg) ->
    alias = msg.match[1].toLowerCase()
    name = msg.match[2].toLowerCase()
    confirm = (if msg.match[3] then msg.match[3].trim().toLowerCase() else false)
    if karma.nameOrAliasExists(alias) && confirm != 'true'
      msg.send "Sorry. #{alias} already tied to user \"#{karma.nameOrAliasExists(alias)}\" with #{karma.get(alias)} karma. Please try again with confirmation."
      return
    else
      karma.alias alias, name
    msg.send "Got it! #{alias} has been aliased to #{name}."

  robot.respond /karma unalias (\S+[^-\s]) (\S+[^-\s])$/i, (msg) ->
    alias = msg.match[1].toLowerCase()
    name = msg.match[2].toLowerCase()
    karma.unalias alias, name
    msg.send "Ok. #{alias} has been unaliased from #{name}."

  robot.respond /karma aliases(?: for)? (\S+[^-\s])$/i, (msg) ->
    name = msg.match[1].toLowerCase()
    subject = karma.findOrInitialize(name)
    aliases = karma.aliases(name)
    msg.send "#{subject}'s current aliases: #{aliases.join(', ')}."

  robot.respond /karma empty ?(\S+[^-\s])$/i, (msg) ->
    subject = msg.match[1].toLowerCase()
    name = karma.kill(subject)
    msg.send "#{name} has had its karma scattered to the winds."

  robot.respond /karma( best)?$/i, (msg) ->
    verbiage = ["The Best"]
    for item, rank in karma.top()
      verbiage.push "#{rank + 1}. #{item.name} - #{item.karma}"
    msg.send verbiage.join("\n")

  robot.router.get "/karma/best", (req, res) ->
    verbiage = []
    for item, rank in karma.top()
      verbiage.push {name: item.name, karma: item.karma}
    res.end JSON.stringify({users: verbiage})

  robot.respond /karma worst$/i, (msg) ->
    verbiage = ["The Worst"]
    for item, rank in karma.bottom()
      verbiage.push "#{rank + 1}. #{item.name} - #{item.karma}"
    msg.send verbiage.join("\n")

  robot.router.get "/karma/worst", (req, res) ->
    verbiage = {}
    for item, rank in karma.bottom()
      verbiage[rank+1] = {name: item.name, karma: item.karma}
    res.end JSON.stringify(verbiage)

  robot.respond /karma all$/i, (msg) ->
    verbiage = ["All Karma"]
    for item, rank in karma.sort()
      verbiage.push "#{rank + 1}. #{item.name} - #{item.karma}"
    msg.send verbiage.join("\n")

  robot.router.get "/karma/all", (req, res) ->
    verbiage = []
    for item, rank in karma.sort()
      verbiage.push {name: item.name, karma: item.karma}
    res.end JSON.stringify({users: verbiage})

  robot.respond /karma (\S+[^-\s])$/i, (msg) ->
    match = msg.match[1].toLowerCase()
    if match != "best" && match != "worst" && match != "all"
      subject = karma.findOrInitialize(match)
      msg.send "\"#{subject}\" has #{karma.get(subject)} karma."

