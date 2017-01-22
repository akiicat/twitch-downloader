# Twitch Downloader
Use Twitch API To Download Vedio and Chat.

## Bundle

install `rest-client` gem.

```sh
bundle install
```

or

```sh
sudo gem install 'rest-client'
```

## Download

```sh
ruby download.rb --help
ruby download.rb https://www.twitch.tv/user_name/v/xxxxxxxx
ruby download.rb xxxxxxxx
```

Downloaded file types

- m3u: vod quality list
- m3u8: vod chunked list
- ts: vedio file
- txt: vod chat list
- json: json file for all chat data

## Concat Ts Files

if you want to concat different part of ts files

```sh
ruby ts_concat.rb <output.ts> <input1.ts> <input2.ts> ...
```

## Get Muted List

usage:

```sh
$ ruby mute_list.rb input.m3u8
00:00:00      0.000 +
01:14:00   4440.000 -
01:22:00   4920.000 +
02:38:00   9480.000 -
02:46:00   9960.000 +
```
