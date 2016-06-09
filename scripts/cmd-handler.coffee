firebase = require('firebase')
authenticate = require('./authenticate')
rootRef = authenticate.root
Q = require('q')
_ = require('lodash')

compareTime = (timeOne, timeTwo) ->
  return 0 if timeOne.hour is timeTwo.hour and timeOne.min is timeTwo.min
  return -1 if timeOne.hour < timeTwo.hour
  return -1 if timeOne.hour is timeTwo.hour and timeOne.min < timeTwo.min
  return 1

confirmTime = (timeOneFrom, timeOneTo, timeTwoFrom, timeTwoTo) ->
  return true if timeOneFrom.hour is timeTwoFrom.hour and timeOneFrom.min is timeTwoFrom.min and timeOneTo.hour is timeTwoTo.hour and timeOneTo.min is timeTwoTo.min
  return false

checkOverlapTime = (roomName, fromTime, toTime) ->
  deferred = new Q.defer()
  rootRef.child('rooms/' + roomName + '/schedules').once 'value', (scheduleSnap) ->
    scheduleSnap.forEach (schedule) ->
      scheduleFrom = schedule.val().timeframe.from 
      scheduleTo = schedule.val().timeframe.to
      return deferred.resolve 'Cannot book room, time slot already filled' unless (compareTime(fromTime, scheduleTo) is 1 or compareTime(toTime, scheduleFrom) isnt 1)
      false
    deferred.resolve false
  deferred.promise

isAdmin = (username, cb) ->
  rootRef.child('admins').orderByKey().equalTo(username).once 'value', (snap) ->
    return cb true if snap.val()
    cb false

formatTime = (t) ->
  numberFormat = (n) ->
    n = parseInt n
    return if n < 10 then '0' + n else n
  return numberFormat(t.hour) + ':' + numberFormat(t.min)

getBookTimes = (roomName, cb) ->
  times = []
  rootRef.child('rooms/' + roomName + '/schedules').once 'value', (scheduleSnap) ->
    scheduleSnap.forEach (schedule) ->
      times.push schedule.val()
      false
    sortedTimes = times.sort (a,b) ->
      return compareTime a.timeframe.from, b.timeframe.from
    cb sortedTimes
      
getBusyRoom = (roomName, cb) ->
  result = ''
  getBookTimes roomName, (times) ->
    _.each times, (time) ->
      result += formatTime(time.timeframe.from) + ' - ' + formatTime(time.timeframe.to) + ' by ' + time.who + '\n'
    return cb 'The following times are not available: ' + '\n' + result if result
    return cb "The room hasn't been booked at all"

getAvailableRoom = (roomName, cb) ->
  result = ''
  from = 
    hour: 8
    min: 0
  getBookTimes roomName, (times) ->
    _.each(times, (time) ->
      to = time.timeframe.from 
      result += formatTime(from) + ' - ' + formatTime(to) + '\n'
      from = time.timeframe.to
    )
    result += formatTime(from) + ' - 17:00'  + '\n'
    cb 'Available times are: ' + '\n' + result

module.exports =
  compareTime: compareTime

  compareWithPast: (time) ->
    now = new Date()
    timeRef = new Date()

    timeRef.setMinutes time.min
    timeRef.setHours time.hour
    timeRef.setSeconds 0
                  
    now.setSeconds 0
    
    return false if timeRef - now > 0

    return true

  addRoom: (roomName, description, username, cb) ->
    isAdmin username, (haveRights)->
      return cb false if not haveRights
      rootRef.child('rooms/' + roomName).set({'description':description})
      cb true

  listRooms: (cb) ->
    roomList = []
    rootRef.child('rooms').once 'value', (roomSnap) ->
      roomSnap.forEach (snap) ->
        roomList.push 
          name: snap.key()
          description: snap.val().description
        false
      cb roomList

  bookRoom: (roomName, fromTime, toTime, username, cb) ->
    checkOverlapTime(roomName, fromTime, toTime).then (result) ->
      return cb result if result isnt false
      rootRef.child('rooms/' + roomName + '/schedules').once 'value', (scheduleSnap) ->
        scheduleSnap.ref().push
          who: username
          timeframe: 
            from: fromTime
            to: toTime
        cb roomName + ' was booked for the specified time frame'

  removeBooking: (roomName, fromTime, toTime, username, cb) ->
    rootRef.child('rooms/' + roomName + '/schedules').orderByChild('who').equalTo(username).once 'value', (snap) ->
      if snap.val()
        found = false
        snap.forEach (dataSnap) ->
          if confirmTime fromTime, toTime, dataSnap.val().timeframe.from, dataSnap.val().timeframe.to
            dataSnap.ref().set(null)
            found = true
            return found
        return cb('Booking has been removed') if found
        return cb('Timeframe stated is wrong')
      return cb('You didn\'t book for this slot, use `check busy <room-name>` to check your time slot')

  checkBusy: (roomName, cb) ->
    getBusyRoom roomName, cb
        
  checkAvailable: (roomName, cb) ->
    getAvailableRoom roomName, cb

  check: (roomName, cb) ->
    deferreds = []
    available = ''
    busy = ''
    rootRef.child('rooms').once 'value', (roomSnap) ->
      return cb('Room does not exist') if not roomSnap.hasChild(roomName)
    
      deferreds.push Q.defer()
      deferreds.push Q.defer()
      
      getAvailableRoom roomName, (result) ->
        available = result
        deferreds[0].resolve()
      
      getBusyRoom roomName, (result) ->
        busy = result
        deferreds[1].resolve()

      promises = _.map deferreds, (d) ->
        return d.promise

      Q.all(promises).then () ->

        cb available + "\n\n" + busy




