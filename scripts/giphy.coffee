# Description:
#   A way to search images on giphy.com
#
# Configuration:
#   HUBOT_GIPHY_API_KEY (defaults to public beta key)
#   HUBOT_GIPHY_RATING (defaults to g aka general audiences)
#
# Commands:
#   hubot gif|giphy|animate me <query> - Returns an animated gif matching the requested search term.
#
# Author
#   kevinthompson (modified by Jonas Arneberg)

giphy =
  api_key: process.env.HUBOT_GIPHY_API_KEY || 'dc6zaTOxFJmzC'
  rating: process.env.HUBOT_GIPHY_RATING || 'g'
  base_url: 'https://api.giphy.com/v1'

module.exports = (robot) ->
  robot.respond /(gif|giphy|animate)( me)? (.*)/i, (msg) ->
    giphyMe msg, msg.match[3], (url) ->
      msg.send url

giphyMe = (msg, query, cb) ->
  endpoint = '/gifs/search'
  url = "#{giphy.base_url}#{endpoint}"

  msg.http(url)
    .query
      q: query
      rating: giphy.rating
      api_key: giphy.api_key
    .get() (err, res, body) ->
      response = undefined
      try
        response = JSON.parse(body)
        images = response.data
        if images.length > 0
          image = msg.random images
          cb image.images.original.url

      catch e
        response = undefined
        cb 'Error'

      return if response is undefined