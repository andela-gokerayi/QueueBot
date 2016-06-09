
Firebase = require('firebase')
FirebaseTokenGenerator = require('firebase-token-generator')
config = require('../config/config')["development"]
rootRef = new Firebase(config.firebase.rootRefUrl)

module.exports = 
  root : rootRef

  firebase : (cb) ->
    tokenGenerator = new FirebaseTokenGenerator(config.firebase.secretKey)
    token = tokenGenerator.createToken(
      uid: 'meeting-room-bot'
      name: 'meeting-room-bot')
    rootRef.authWithCustomToken token, (error, authData) ->
      return cb error if error 
      cb null, rootRef
   