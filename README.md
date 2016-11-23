# Twitch Downloader
Use Twitch API To Download Vedio and Chat.

## Bundle

install `rest-client' gem.

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

## Tool For Concat Ts Files

if you want to concat different part of ts files

```sh
ruby ts_concat.rb <output.ts> <input1.ts> <input2.ts> ...
```
