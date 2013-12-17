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
log        = console.log.bind   console, '\x1b[32m  '
logWait    = console.log.bind   console, '\x1b[33m  '
logErr     = console.error.bind console, '\x1b[31m  '


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
        logErr "#{ if title then 'track' else 'artist' } not found"
        process.exit 1

  .on 'error', netErr


parse = (raw) ->
  try
    JSON.parse raw
  catch
    logErr 'couldn\'t parse the page'
    process.exit 1


download = (obj) ->
  return unless obj
  pattern = /&\w+;|[^\w\s\(\)\-]/g
  artist  = obj.user.username.replace(pattern, '').trim()
  title   = obj.title.replace(pattern, '').trim()
  logWait 'fetching: ' + title unless play
  http.get obj.streamUrl, (res) ->
    http.get res.headers.location, (res) ->
      if play
        log "playing:  #{ title }\n"
        res.pipe earPipe
      else
        res.pipe fs.createWriteStream "./#{ outputDir }/#{ artist } - #{ title }.mp3"

      res.on 'end', ->
        process.exit 0 if play
        log 'done:     ' + title
        if ++downloaded is trackCount
          log()
          log "wrote #{ downloaded } file#{ ('s' if downloaded > 1) or '' } to ./#{ outputDir }"
          log "took about #{ s = Math.round (new Date - start) / 1000 } second#{ ('s' if s isnt 1) or '' }\n"
          process.exit 0

    .on 'error', netErr
  .on 'error', netErr


fsErr = ->
  logErr 'you don\'t have permission to write files here'
  process.exit 1


netErr = (e) ->
  return if play and e.code is 'ECONNRESET'
  logErr 'network error:  ', e
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
        logErr err
        fsErr()
    else
      makeDir artist, ++n, cb


if (i = argv.indexOf '-p') > -1 or (i = argv.indexOf '--play') > -1
  play = true
  argv.splice i, 1
  earPipe = new (require 'ear-pipe')
  earPipe.process.on 'error', (err) ->
    if err.code is 'ENOENT'
      logErr 'SoX is required for audio playback and does not appear to be installed'
    else
      logErr 'error:', err
    process.exit 1


if argv.length < 3
  logErr 'pass an artist name as the first argument'
  process.exit 1


if play
  unless argv[3]
    logErr 'play mode only works with a single track name'
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

