# Description:
#   Track Punishment stickers for the team
#
# Dependencies:
#   None
#
# Configuration:
#   STICKER_ALLOW_ADD_SELF
#   STICKER_ALLOW_REMOVE_SELF
#
# Commands:
#   hubot sticker assign username stickername - Give the user that sticker
#   hubot sticker remove username stickername - Removes one of those stickers for that user
#   hubot sticker list - Shows all active stickers
#   hubot sticker list user - Shows the stickers for that user
#   hubot sticker create <sticker> - Creates a new sticker
#   hubot sticker leaderboard - Shows everyone's sticker count
#
# Author:
#   Gareth Oates <goatie@gmail.com>
#

Util = require "util"

class Stickers

  constructor: (@robot) ->
    @cache = {}

    @STICKER_ALLOW_ADD_SELF = process.env.STICKER_ALLOW_ADD_SELF or true
    @STICKER_ALLOW_REMOVE_SELF = process.env.STICKER_ALLOW_REMOVE_SELF or true

    @stickersList = []

    @robot.brain.on 'loaded', =>
    if @robot.brain.data.stickers
      @cache = @robot.brain.data.stickers

  createSticker: (sticker) ->
    @stickersList.push sticker

  assignSticker: (user, sticker) ->
    if not @cache[user.name]?
      @cache[user.name] = []

    if not @cache[user.name][sticker]?
      @cache[user.name][sticker] = 0

    @cache[user.name][sticker] += 1
    @robot.brain.data.stickers = @cache

  setNewListOfStickers: (stickers) ->
    @stickersList = stickers

  removeUserSticker: (user, sticker) ->
    if @cache[user.name]?
      if @cache[user.name][sticker]?
        @cache[user.name][sticker] -= 1
        @cache[user.name][sticker] = Math.max(0, @cache[user.name][sticker])
    @robot.brain.data.stickers = @cache

  assignStickerResponse: (user, sticker) ->
    @add_sticker_responses = [
      "#{user.name} just got hit with the #{sticker} sticker!",
      "Congratulations #{user.name} you just earned yourself the #{sticker} sticker!",
      "#{user.name} should have known better, now they have a #{sticker} sticker!"]

    @add_sticker_responses[Math.floor(Math.random() * @add_sticker_responses.length)]

  removeUserStickerResponse: (user, sticker) ->
    @remove_sticker_responses = [
      "#{user.name} is being let off the hook! One #{sticker} removed!",
      "Unbelievable! #{user.name} got away with it! That's one less #{sticker} sticker!"
      "Someone's in the good books! #{sticker} removed for #{user.name}"
      "The sticker gods are smiling on #{user.name} today. That's a #{sticker} sticker removed"]

    @remove_sticker_responses[Math.floor(Math.random() * @remove_sticker_responses.length)]

  selfDeniedResponse: (name) ->
    @self_denied_responses = [
      "Very noble #{name} but I'm afraid you can't give yourself a sticker",
      "Did you really mean to give yourself a sticker?",
      "You can't sticker yourself!"
      "A colleague will have to give you that sticker I'm afraid!"
    ]

  selfDeniedRemoval: (name) ->
    @self_denied_removal = [
      "Nice try #{name}!",
      "If only it was that easy!",
      "I don't think so #{name}!"
    ]

  getCanStickerSelf: ->
    return @STICKER_ALLOW_ADD_SELF

  getCanremoveUserStickerSelf: ->
    return @STICKER_ALLOW_REMOVE_SELF

  stickerExists: (sticker) ->
    return sticker in @stickersList

  userExists: (user) ->
    users = @robot.brain.usersForFuzzyName(user)
    if users.length is 1
      return { success: true, user: users[0] }
    else
      return { success: false }

  getStickersForUser: (user) ->
    k = if @cache[user] then @cache[user] else 0
    return k

  getEveryone: ->
    k = if @cache? then @cache else 0
    return k

module.exports = (robot) ->
  stickers = new Stickers robot

  robot.respond /sticker assign @*(\w*) (\w*)/i, (msg) ->
    robot.logger.info "Assign a Sticker Regex matched"
    subject = msg.match[1].toLowerCase().trim()
    validUser = stickers.userExists subject
    if not validUser.success
      msg.send "I don't know who #{subject} is..."
      return
    sticker = msg.match[2]
    if not stickers.stickerExists sticker
      msg.send "There is no sticker set up for #{sticker}. Use sticker create #{sticker} to add it."
      return

    if stickers.getCanStickerSelf() or msg.message.user.name.toLowerCase() != subject
      stickers.assignSticker validUser.user, sticker
      msg.send "#{stickers.assignStickerResponse(validUser.user, sticker)}"
    else
      msg.send msg.random stickers.selfDeniedResponse(msg.message.user.name)

  robot.respond /sticker remove @*(\w*) (\w*)/i, (msg) ->
    robot.logger.info "Remove Sticker Regex Match"
    subject = msg.match[1].toLowerCase().trim()
    validUser = stickers.userExists subject
    if not validUser.success
      msg.send "I don't know who #{subject} is..."
      return

    sticker = msg.match[2].trim()

    if stickers.getCanremoveUserStickerSelf() or msg.message.user.name.toLowerCase() != subject
      stickers.removeUserSticker validUser.user, sticker
      msg.send "#{stickers.removeUserStickerResponse(validUser.user, sticker)}"
    else
      msg.send msg.random stickers.selfDeniedRemoval(msg.message.user.name)

  robot.respond /sticker create (\w*)/i, (msg) ->
    robot.logger.info "Create new Sticker Regex matched"
    sticker = msg.match[1].trim()
    if not stickers.stickerExists(sticker) and sticker != "sticker"
      stickers.createSticker(sticker)
      msg.send "A new sticker called #{sticker} was created."
    else
      msg.send "That sticker already exists or is not allowed!"

  robot.respond /sticker destroy (\w*)/i, (msg) ->
    robot.logger.info "Destroy Sticker Regex matched"
    sticker = msg.match[1].trim()
    if not stickers.stickerExists(sticker)
        msg.send "I'm sorry, I can't destroy that which does not already exist"
        return

    list = stickers.stickersList
    indexOfSticker = list?.indexOf(sticker)
    list.splice(indexOfSticker, 1)
    stickers.setNewListOfStickers list
    msg.send "Okay, now nobody can be assigned the #{sticker} sticker"

  robot.respond /sticker list @*(\w+)/i, (msg) ->
    robot.logger.info "List User Stickers Regex Matched"
    subject = msg.match[1].toLowerCase().trim()
    validUser = stickers.userExists subject
    if not validUser.success
      msg.send "I don't know who #{subject} is..."
      return

    user = validUser.user
    verbiage = ["#{user.name} has the following stickers:"]
    stickerListObject = stickers.getStickersForUser validUser.user.name
    if stickerListObject?
      for key, val of stickerListObject
        if val > 0
          verbiage.push "#{key}: #{val}"
    if verbiage.length == 1
      msg.send "#{user.name} has no stickers!"
    else
      msg.send verbiage.join("\n")

  robot.respond /sticker list$/i, (msg) ->
    robot.logger.info "List All Stickers Regex matched"
    stickersList = stickers.stickersList
    outputList = ["Currently Active Stickers:"]
    for sticker in stickersList
      outputList.push sticker
    if outputList.length == 1
      msg.send "No Stickers Found.  Create a new sticker with the ``sticker create <stickername>`` command"
    else
      msg.send outputList.join("\n")

  robot.respond /sticker leaderboard/i, (msg) ->
    robot.logger.info "Leaderboard List Regex matched"
    theCache = stickers.getEveryone()
    for key,value of theCache
      verbiage = ["#{key} has the following stickers:"]
      stickerListObject = stickers.getStickersForUser key
      if stickerListObject?
        for key, val of stickerListObject
          if val > 0
            verbiage.push "#{key}: #{val}"
      msg.send verbiage.join("\n")

  robot.respond /sticker debug/i, (msg) ->
    robot.logger.info "#{Util.inspect(stickers.getEveryone())}"
    msg.send "#{Util.inspect(robot.brain.data.stickers)}"


