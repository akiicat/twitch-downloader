# Twitch Downloader
Use Twitch API To Download Vedio and Chat.

## Download

```sh
# Usage: download.rb [options default -lvc] <url or vod id>
#    -l, --list                       download vod m3u list and m3u8 list
#    -v, --vod                        download vod video as ts file
#    -c, --chat                       download vod chat
ruby download.rb https://www.twitch.tv/user_name/v/xxxxxxxx
ruby download.rb -lvc xxxxxxxx

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
