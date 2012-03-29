###
* soundscrape
* Dan Motzenbecker
###

http = require 'http'
fs   = require 'fs'

rootHost = 'soundcloud.com'
argLen = process.argv.length


if argLen < 2
  return console.log 'pass an artist name!'

artist = process.argv[2]

if argLen > 3
  trackName = process.argv[3]


http.get
  host: rootHost
  path: '/' + artist + (if trackName? then '/' + trackName else '')
, (res) ->
  data = ''
  res.on 'data', (chunk) ->
    data += chunk

  res.on 'end', ->
    tracks = data.match /(window\.SC\.bufferTracks\.push\().+(?=\);)/gi

    if trackName?
      download parse tracks[0]
    else
      download parse track for track in tracks

    console.log ''


parse = (raw) ->
  JSON.parse raw.substr 28


download = (obj) ->
  artist = obj.user.username
  title = obj.title
  console.log '\x1b[33mfetching: ' + title + '\x1b[0m'
  http.get
    host: 'media.' + rootHost
    path: obj.streamUrl.match /\/stream\/.+/
  , (res) ->
    res.on 'end', ->
      http.get
        host: 'ak-media.' + rootHost
        path: res.headers.location.substr 30
      , (res) ->
        file = fs.createWriteStream './' + artist + ' - ' + title + '.mp3'

        res.on 'data', (chunk) ->
          file.write chunk

        res.on 'end', ->
          file.end()
          console.log '\x1b[32mdone:     ' + title + '\x1b[0m'

