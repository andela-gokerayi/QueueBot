help = require('./help')
cmdHandler = require('./cmd-handler')
_ = require('lodash')
schedule = require('./schedule')

# check if a string containing a time it is in the right format
# format: hh:mm
# return
#   {
#     hour: integer
#     min: integer
#   }
checkTime = (strTime) ->
  reg = new RegExp(/([0-9]+):([0-9]+)/)
  match = strTime.match reg
  hour = parseInt(match[1])
  min = parseInt(match[2])
  # check if it  a correct time
  return {hour: hour, min: min} if hour <= 23 and min <= 59
  return false

module.exports = (robot) ->
  # run crons for deleting scheduls and notifying users
  schedule.run(robot)

  # print the help
  robot.respond /help/i, (res) ->
    res.send help()

  # print the bot's description and job
  robot.respond /information/i, (res) ->
    res.send 'I book meeting rooms for you all'

  # adding a room  and set the description
  # ADMINS OLNY
  # ex: add room <roomname>:<description>
  # default description "New room"
  robot.respond /add room ([^:]*)([:]{0,1})(.*)/i, (res) ->
    room = res.match[1]
    # in case we have no description
    description = res.match[3] or "New room"
    username = res.message.user.name

    # check if user is an admin
    cmdHandler.addRoom room, description, username, (success) ->
      return res.send "You don't have rights to add a room" unless success
      res.send "Room was added!"

  # list available rooms
  robot.respond /list rooms/i, (res) ->
    cmdHandler.listRooms (rooms) ->
      result = _.map(rooms, (room)-> 
        return room.name + ": " + room.description
        ).join('\n')
      res.send '```' + result + '```'

  # book a room
  # ex: book <roomname> hh:mm - hh:mm
  robot.respond /book (.+) ([0-9]+:[0-9]+)([ -]+)([0-9]+:[0-9]+)/i, (res) ->
    roomName = res.match[1].trim()
    # convert time from string to object
    fromTime = checkTime res.match[2]
    toTime = checkTime res.match[4]
    # who is booking the room
    username = res.message.user.name
    return res.send 'Invalid From-time' if fromTime is false
    return res.send 'Invalid To-time' if toTime is false
    return res.send 'Room can be booked only from 8:00' if fromTime.hour < 8
    return res.send 'Room cannot be booked later than 17:00' if toTime.hour > 17
    return res.send 'Invalid time interval' if cmdHandler.compareTime(fromTime, toTime) is 1
    return res.send 'You cannot book a room in the past' if cmdHandler.compareWithPast(fromTime)
    cmdHandler.bookRoom roomName, fromTime, toTime, username, (result) ->
      res.send result

  # delete book a room
  # ex: book <roomname> hh:mm - hh:mm
  robot.respond /remove (.+) ([0-9]+:[0-9]+)([ -]+)([0-9]+:[0-9]+)/i, (res) ->
    roomName = res.match[1].trim()
    # convert time from string to object
    fromTime = checkTime res.match[2]
    toTime = checkTime res.match[4]
    # who is booking the room
    username = res.message.user.name
    return res.send 'Invalid From-time' if fromTime is false
    return res.send 'Invalid To-time' if toTime is false
    cmdHandler.removeBooking roomName, fromTime, toTime, username, (message) ->
      res.send message

  # check busy for a room
  # ex: 
  #     check busy <roomname>
  robot.respond /check busy (.+)/i, (res) ->
    roomName = res.match[1]
    cmdHandler.checkBusy roomName, (result) ->
      res.send '```' + result + '```'


  # check availability for a room
  # ex: 
  #     check available <roomname>
  robot.respond /check available (.+)/i, (res) ->
    roomName = res.match[1]
    cmdHandler.checkAvailable roomName, (result) ->
      res.send '```' + result + '```'

  # check status of a room
  # show busy times as well as available times
  # ex:
  #        check <roomname>
  robot.respond /check (?!available|busy)(.+)/i, (res) ->
    roomName = res.match[1]
    cmdHandler.check roomName, (result) ->
      res.send '```' + result + '```'

