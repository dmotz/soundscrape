# soundscrape

SoundCloud command line player / downloader


### Installation:

```
$ npm install -g soundscrape
```


### Usage:

#### Download all tracks from an artist at once:

```
$ soundscrape claque
```
(that's me)


#### Download a single track:

```
$ soundscrape claque diver
```

Hyphenate track names with spaces (use the URL endpoint as your guide):

```
$ soundscrape claque hotel-splendid
```

You can also pass a space-separated list of track names as arguments.

Files are downloaded in parallel to the directory you ran `soundscrape` from.


#### Stream a track to your speakers by passing `-p` or `--play`:

```
$ soundscrape claque very-special -p
```

Playing tracks requires [SoX](http://sox.sourceforge.net) to be installed.

Have fun; use it ethically.
