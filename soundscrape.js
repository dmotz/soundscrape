
/*
* soundscrape
* Dan Motzenbecker
*/

(function() {
  var argLen, artist, download, fs, http, rootHost, track;

  http = require('http');

  fs = require('fs');

  rootHost = 'soundcloud.com';

  argLen = process.argv.length;

  if (argLen < 2) return console.log('pass an artist name!');

  artist = process.argv[2];

  if (argLen > 3) track = process.argv[3];

  http.get({
    host: rootHost,
    path: '/' + artist + (track != null ? '/' + track : '')
  }, function(res) {
    var data;
    data = '';
    res.on('data', function(chunk) {
      return data += chunk;
    });
    return res.on('end', function() {
      var t, tracks, _i, _len;
      tracks = data.match(/(window\.SC\.bufferTracks\.push\().+(?=\);)/gi);
      for (_i = 0, _len = tracks.length; _i < _len; _i++) {
        t = tracks[_i];
        download(JSON.parse(track.substr(28)));
      }
      return console.log('');
    });
  });

  download = function(obj) {
    var title;
    artist = obj.user.username;
    title = obj.title;
    console.log('\x1b[33mfetching: ' + title + '\x1b[0m');
    return http.get({
      host: 'media.' + rootHost,
      path: obj.streamUrl.match(/\/stream\/.+/)
    }, function(res) {
      return res.on('end', function() {
        return http.get({
          host: 'ak-media.' + rootHost,
          path: res.headers.location.substr(30)
        }, function(res) {
          var file;
          file = fs.createWriteStream('./' + artist + ' - ' + title + '.mp3');
          res.on('data', function(chunk) {
            return file.write(chunk);
          });
          return res.on('end', function() {
            file.end();
            return console.log('\x1b[32mdone:     ' + title + '\x1b[0m');
          });
        });
      });
    });
  };

}).call(this);
