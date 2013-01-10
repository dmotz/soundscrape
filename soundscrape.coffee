#!/usr/bin/env coffee

###
 * soundscrape
 * SoundCloud command line downloader
 * Dan Motzenbecker <motzdc@gmail.com>
 * MIT License
###


http = require 'http'
fs   = require 'fs'
url  = require 'url'

rootHost = 'soundcloud.com'
page     = 1
argLen   = process.argv.length
params   = {}


scrape = ->
  http.get
    host: rootHost
    path: "/#{ params.artist }/#{ params.trackName or 'tracks?page=' + page }"
  , (res) ->

    data = ''
    res.on 'data', (chunk) -> data += chunk
    res.on 'end', ->
      tracks = data.match /(window\.SC\.bufferTracks\.push\().+(?=\);)/gi
      if params.trackName
        download parse tracks[0]
        console.log ''
      else
        download parse track for track in tracks
        if tracks.length is 10
          page++
          scrape()
        else
          console.log ''


parse = (raw) ->
  chaff = raw.indexOf '{'
  return false if chaff is -1
  try
    JSON.parse raw.substr chaff
  catch e
    console.log '\x1b[31mcouldn\'t parse this page.\x1b[0m'
    process.exit 1


download = (obj) ->
  return unless obj
  pattern = /&\w+;|[^\w|\s]/g
  artist = obj.user.username.replace pattern, ''
  title  = obj.title.replace pattern, ''
  console.log "\x1b[33mfetching: #{ title }\x1b[0m"
  http.get
    host: 'media.' + rootHost
    path: obj.streamUrl.match /\/stream\/.+/
  , (res) ->

    res.on 'end', ->
      mediaUrl = url.parse res.headers.location
      http.get
        host: mediaUrl.host
        path: mediaUrl.path
      , (res) ->
        file = fs.createWriteStream "./#{ artist } - #{ title }.mp3"

        res.on 'data', (chunk) -> file.write chunk
        res.on 'end', ->
          file.end()
          console.log "\x1b[32mdone:     #{ title }\x1b[0m"


init = ->
  if argLen <= 2
    console.log '\x1b[31mpass an artist name!\x1b[0m'
    process.exit 1

  testFile = '.soundscrape_' + Date.now()
  try
    writeTest = fs.createWriteStream testFile
  catch e
    console.log '\x1b[31myou don\'t have permission to write files here\x1b[0m'
    process.exit 1

  writeTest.end()
  fs.unlink testFile, (err) -> console.log err if err

  params.artist = process.argv[2]
  params.trackName = process.argv[3] if argLen > 3
  scrape()


init()
