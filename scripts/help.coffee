_ = require('lodash')

module.exports =
  _.template(
     "`information` - Introduces self" + "\n"  +
     "`list rooms` - Gives a list of all existing rooms" + "\n" +
     "`book <room-name> <from> - <to>` - Books the specified room for the timeframe specified (24-hour Format)" + "\n" +
     "`check <room-name>` - Show the calender of the room specified" + "\n" +
     "`check available <room-name>` - Show available time for the room" + "\n" +
     "`check busy <room-name>` - Show busy time for the room" + "\n" +
     "`remove <room-name> <from> - <to>` - Removes bookings made for the specified room at the timeframe specified (24-hour Format)" + "\n" +
     "`add room <room-name>:<room-desciption>` - Add a room to the room list ( only admin can do it)"
  );