# Description:
#   Allows users to store a worklog per channel that gets saved to a file,
#   one per month. Also allows simple playback of logs for a certain date.
#
# Dependencies:
#   moment, fs, mkdirp
#
# Configuration:
#   None
#
# Commands:
#   @wl <some message here> - Logs the message given to the worklog
#   @swl <YYYY-MM-DD> [for <channel>] - Displays worklog entries from given date (and channel)
#
# Notes:
#   None
#
# Author:
#   Kristian Rønningen
#   Jonas Arneberg

moment      = require 'moment'
fs          = require 'fs'
mkdirp      = require 'mkdirp'
querystring = require 'querystring'
url         = require 'url'

basedir = '~/worklogs'

module.exports = (robot) ->
    # Show WorkLog entries for a certain date for a certain room (or current if omitted)
    robot.hear /^([@!]swl) (\d\d\d\d)-(\d\d)-(\d\d)( for ([^\s]+))?$/i, (msg) ->
        [year, month, day] = msg.match[2..4]
        if msg.match[6]
            room = msg.match[6]
        else
            room = robot.adapter.client.getChannelNameByID(msg.message.room)
        filename = basedir + '/' + year + '/' + year + '-' + month + '.json'
        re = new RegExp("^" + year + "-" + month + "-" + day + "T")
        logTable = ''
        fs.stat filename, (error, stats) ->
            if error
                msg.send "No worklog found for that month.\n"
            else
                for line in fs.readFileSync(filename).toString().split '\n'
                    if line?.length
                        data = JSON.parse(line)
                        if (data.time.match re) and (data.room is room)
                            logTable += "| " + moment(data.time).format('YYYY-MM-DD HH:mm:ss ZZ') + " | " + data.room + " | " + data.user + " | " + data.message + " |\n"
                if logTable
                    msg.send "| Time | Channel | User | Entry |\n| :--- | :--- | :--- | :---- |\n" + logTable.trim()
                else
                    msg.send "No log entries found from " + year + "-" + month + "-" + day + " for channel " + room + ".\n"

    # Log a WorkLog entry
    robot.hear /^([@!]wl)( .*)?/i, (msg) ->
        if msg.match[2]
            message = msg.match[2].trim()
        dir = basedir + '/' + moment().format('YYYY')
        file = dir + '/' + moment().format('YYYY-MM') + '.json'
        if message
            mkdirp dir, (error) ->
                if error
                    msg.reply("There was an error saving your worklog entry!")
                    robot.logger.error("There was an error saving a worklog entry. Unable to create directory.")
                else
                    logEntry = {'time': moment().toISOString(), 'user': msg.message.user.name, 'room': robot.adapter.client.getChannelNameByID(msg.message.room), 'message': message}
                    fs.appendFile file, JSON.stringify(logEntry) + '\n', (error) ->
                        if error
                            msg.reply("There was an error saving your worklog entry!")
                            robot.logger.error("There was an error saving a worklog entry." + error)
                        else
                            msg.reply("Ok, saved that to the worklog.")
        else
            msg.reply 'WorkLog messages logged (' + msg.match[1] + ' <Message here>) will be viewable with @swl <YYYY-MM-DD> [for <channel>]\n'

    # Expected GET url is something like this: /?year=2016&month=05&rooms=ops-fronter<,frops,..>
    robot.router.get "/swl", (req, res) ->
        query = querystring.parse(url.parse(req.url).query)

        if query.year? and query.month? and query.rooms?
            if isFinite(query.year)
                year = query.year
            else if query.year is "now"
                year = moment().format('YYYY')
            if isFinite(query.month)
                month = query.month
            else if query.month is "now"
                month = moment().format('MM')
            re = new RegExp("^[a-z0-9-,]+")
            if query.rooms.match re
                rooms = query.rooms.split ','
        else
            res.send "Invalid GET request. Missing arguments.\n"
            res.end "OK"

        if year? and month? and rooms?
            filename = basedir + '/' + year + '/' + year + '-' + month + '.json'
            logTable = ''
            fs.stat filename, (error, stats) ->
                if error
                    res.send "No worklog found for that month.\n"
                else
                    for line in fs.readFileSync(filename).toString().split '\n'
                        if line?.length
                            data = JSON.parse(line)
                            if (data.room in rooms) or (query.rooms is "all")
                                logTable += """
                                <tr>
                                    <td style="white-space: nowrap;">#{moment(data.time).format('YYYY-MM-DD HH:mm:ss ZZ')}</td>
                                    <td style="white-space: nowrap;">#{data.room}</td>
                                    <td style="white-space: nowrap;">#{data.user}</td>
                                    <td>#{data.message}</td>
                                </tr>

                                """
                    if logTable
                        res.send """
                        <html>
                        <head>
                            <title>Worklog for #{year}-#{month}</title>
                            <style>
                                table {
                                    width: auto;
                                    border-spacing: 0;
                                }
                                td {
                                    padding-right: 5px;
                                    padding-left: 5px;
                                    padding-top: 3px;
                                }
                                th {
                                    text-align: left;
                                    padding-left: 5px;
                                }
                                tr:nth-of-type(odd) {
                                    background: #cce6ff;
                                }
                                tr:nth-of-type(even) {
                                    background: #e6f2ff;
                                }
                                td:last-child {
                                    width: 100%;
                                }
                            </style>
                        </head>
                        <table>
                        <tr>
                            <th style="white-space: nowrap; background: lightgray">Time</th>
                            <th style="white-space: nowrap; background: lightgray">Channel</th>
                            <th style="white-space: nowrap; background: lightgray">User</th>
                            <th style="background: lightgray">Entry</th>
                        </tr>
                        #{logTable}
                        </table>
                        """
                    else
                        res.send "No log entries found from " + year + "-" + month + " for channel " + query.rooms + ".\n"
                res.end "OK"
        else
            res.send "Invalid GET request. Missing arguments.\n"
            res.end "OK"