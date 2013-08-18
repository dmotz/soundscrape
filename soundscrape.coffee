#!/usr/bin/env coffee

###
 * soundscrape
 * SoundCloud command line downloader
 * Dan Motzenbecker <dan@oxism.com>
 * MIT License
###


http = require 'http'
fs   = require 'fs'

baseUrl    = 'http://soundcloud.com/'
rx         = /bufferTracks\.push\((\{.+?\})\)/g
trackCount = downloaded = 0
argLen     = process.argv.length
params     = {}


scrape = (page) ->
  http.get "#{ baseUrl }#{ params.artist }/#{ params.trackName or 'tracks?page=' + page }", (res) ->
    data = ''
    res.on 'data', (chunk) -> data += chunk
    res.on 'end', ->
      while track = rx.exec data
        download parse track[1]
        scrape ++page unless ++trackCount % 10

      unless trackCount
        console.log "\x1b[31m  #{ if params.trackName then 'track' else 'artist' } not found  \x1b[0m"
        process.exit 1


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
  http.get obj.streamUrl, (res) ->
    http.get res.headers.location, (res) ->
      file = fs.createWriteStream "./#{ artist } - #{ title }.mp3"
      res.on 'data', (chunk) -> file.write chunk
      res.on 'end', ->
        file.end()
        console.log "\x1b[32mdone:     #{ title }\x1b[0m"
        process.exit 0 if ++downloaded is trackCount


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
  scrape 1


init()
