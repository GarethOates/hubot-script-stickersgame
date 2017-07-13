# Description:
#   A Hubot script to interact with Atlassian Confluence
#
# Dependencies:
#   atlassian-confluence
#
# Configuration:
#   CONFLUENCE_HOST
#   CONFLUENCE_USERNAME
#   CONFLUENCE_PASSWORD
#   CONFLUENCE_CONTEXT
#
# Commands:
#   hubot search confluence <query> - Searches the confluence for matching pages and returns a link.
#
# Author:
#   justmiles

confluence          = require 'atlassian-confluence'
confluence.host     = process.env.CONFLUENCE_HOST      or ''
confluence.username = process.env.CONFLUENCE_USERNAME  or ''
confluence.password = process.env.CONFLUENCE_PASSWORD  or ''
confluence.context  = process.env.CONFLUENCE_CONTEXT   or '/wiki'

unless confluence.host?
  robot.logger.warning 'The CONFLUENCE_HOST environment variable not set'

unless confluence.username?
  robot.logger.warning 'The CONFLUENCE_USERNAME environment variable not set'

module.exports = (robot) ->

  robot.respond /((search|show) confluence) (.*)/i, (msg) ->
    confluence.simpleSearch msg.match[3], { limit : 3, expand: 'metadata,space,container,version' }, (res) ->
      if res
        if res.results and res.results.length > 0
          res.results.forEach (result) ->
            results = {
              "fallback": "#{result.title} - https://#{confluence.host}#{confluence.context}#{result._links.webui}",
              "color": "#f0faf3",
              "title": "#{result.title}",
              "title_link": "https://#{confluence.host}#{confluence.context}#{result._links.webui}",
              "fields": [
                {
                  "title": "Space",
                  "value": result.space.name,
                  "short": true
                },
                {
                  "title": "Latest Author",
                  "value": result.version.by.displayName,
                  "short": true
                }
              ]
            }
            robot.emit 'slack-attachment',
              message:
                room: msg.message.room
              content: results
        
        else
          msg.reply "No results found for '#{msg.match[2]}'"
      
      else
        msg.send 'Sorry, your search has failed.  Please check the logs.'
        console.log res