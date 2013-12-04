#!/usr/bin/env coffee

###
 * soundscrape
 * SoundCloud command line downloader
 * Dan Motzenbecker <dan@oxism.com>
 * MIT License
###


http = require 'http'
fs   = require 'fs'

{argv}     = process
baseUrl    = 'http://soundcloud.com/'
trackCount = downloaded = 0
outputDir  = null
start      = new Date
play       = false


scrape = (page, artist, title) ->
  http.get "#{ baseUrl }#{ artist }/#{ title or 'tracks?page=' + page }", (res) ->
    data = ''
    res.on 'data', (chunk) -> data += chunk
    res.on 'end', ->
      rx = /bufferTracks\.push\((\{.+?\})\)/g
      while track = rx.exec data
        download parse track[1]
        scrape ++page, artist, title unless ++trackCount % 10
        return if title

      unless trackCount
        console.error "\x1b[31m  #{ if title then 'track' else 'artist' } not found  \x1b[0m"
        process.exit 1

  .on 'error', netErr


parse = (raw) ->
  try
    JSON.parse raw
  catch
    console.error '\x1b[31m  couldn\'t parse the page \x1b[0m'
    process.exit 1


download = (obj) ->
  return unless obj
  pattern = /&\w+;|[^\w\s\(\)\-]/g
  artist  = obj.user.username.replace(pattern, '').trim()
  title   = obj.title.replace(pattern, '').trim()
  console.log "\x1b[33m  fetching: #{ title }  \x1b[0m" unless play
  http.get obj.streamUrl, (res) ->
    http.get res.headers.location, (res) ->
      if play
        console.log "\x1b[32m  playing:  #{ title }  \x1b[0m"
        res.pipe earPipe
      else
        res.pipe fs.createWriteStream "./#{ outputDir }/#{ artist } - #{ title }.mp3"

      res.on 'end', ->
        process.exit 0 if play
        console.log "\x1b[32m  done:     #{ title }  \x1b[0m"
        if ++downloaded is trackCount
          console.log "\n\x1b[32m  wrote #{ downloaded } " +
            "#{ if trackCount is 1 then 'file' else 'files' } to ./#{ outputDir }"
          console.log "  took #{ new Date - start }ms  \x1b[0m\n"
          process.exit 0

    .on 'error', netErr
  .on 'error', netErr


fsErr = ->
  console.error '\x1b[31m  you don\'t have permission to write files here  \x1b[0m'
  process.exit 1


netErr = (e) ->
  return if play and e.code is 'ECONNRESET'
  console.error '\x1b[31m  network error:  \x1b[0m', e
  process.exit 1


makeDir = (artist, n, cb) ->
  path = if n then "#{ artist } #{ n }" else artist
  fs.stat path, (err, stats) ->
    if err
      if err.code is 'ENOENT'
        fs.mkdir path, (err) ->
          fsErr() if err
          cb path
      else
        console.error err
        fsErr()
    else
      makeDir artist, ++n, cb


if (i = argv.indexOf '-p') > -1 or (i = argv.indexOf '--play') > -1
  play = true
  argv.splice i, 1
  earPipe = new (require 'ear-pipe')
  earPipe.process.on 'error', (err) ->
    console.error err
    process.exit 1


if argv.length < 3
  console.error '\x1b[31m  pass an artist name as the first argument  \x1b[0m'
  process.exit 1


if play
  unless argv[3]
    console.error '\x1b[31m  play mode only works with a single track name  \x1b[0m'
    process.exit 1

  scrape 1, argv[2], argv[3]

else
  makeDir argv[2], 0, (path) ->
    outputDir = path
    if argv.length is 3
      scrape 1, argv[2]
    else
      for n in [3...argv.length]
        scrape 1, argv[2], argv[n]

