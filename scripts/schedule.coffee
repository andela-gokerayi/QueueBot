CronJob = require('cron').CronJob
firebase = require('firebase')
authenticate = require('./authenticate')
rootRef = authenticate.root

checkTimeDiff = (hour, min, diff) ->
  now = new Date()
  from = new Date()

  from.setMinutes min
  from.setHours hour
  from.setSeconds 0
                
  now.setSeconds 0

  currentDiff = (from - now)/1000/60 - diff
  
  return false if currentDiff < 0 or currentDiff > 1

  return true


module.exports = 
  run: (robot) -> 
    # to run 6 am everyday
    new CronJob '0 0 6 * * *', () ->
      rootRef.child('rooms').once 'value', (snap) ->
        snap.forEach (room) ->
          console.log room.val()
          room.ref().child('schedules').set null
          false
    , null, true, 'Africa/Lagos'

    new CronJob '0 */2 * * * *', () ->
      rootRef.child('rooms').once 'value', (snap) ->
        snap.forEach (room) ->
          room.ref().child('schedules').once 'value', (scheduleSnap) ->
            scheduleSnap.forEach (schedule) ->
              from = schedule.val().timeframe.from
              to = schedule.val().timeframe.to
              username = schedule.val().who
              notifyToStart = checkTimeDiff from.hour, from.min, 5
              notifyToEnd = checkTimeDiff to.hour, to.min, 5
              user = 
                room : username
              robot.send user, 'Hi ' + username + ', your meeting starts in 5 minutes in room ' + room.key() if notifyToStart
              robot.send user, 'Hi ' + username + ', your meeting ends in 5 minutes in room ' + room.key() if notifyToEnd
              false
          false
    , null, true, 'Africa/Lagos'
