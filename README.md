# Twitch Downloader
Use Twitch API To Download Vedio and Chat.

## Usage
### Get Client ID
[Register your Application](https://www.twitch.tv/kraken/oauth2/clients/new)

- Name: What you want
- Redirect URI: Set this to `http://localhost` for testing
- Application Category: `Browser Extension` or random choose one

Get the client ID and modify `download.rb`'s client_id

```ruby
# download.rb
# client_id = ''
client_id = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
```

[Manage Your Twitch API](https://www.twitch.tv/settings/connections)

### Download

download vedio and chat which default path at `vedio/date_vedioId`

```sh
# Usage: download.rb [options default -lvc] <url or vod id>
#    -l, --list                       download vod m3u list and m3u8 list
#    -v, --vod                        download vod video as ts file
#    -c, --chat                       download vod chat
ruby download.rb https://www.twitch.tv/user_name/v/xxxxxxxx
ruby download.rb -lvc xxxxxxxx

```
Downloaded files

- m3u: vod quality list
- m3u8: vod chunked list
- ts: vedio file
- txt: vod chat list
- json: json file for all chat data

## Tools
### Concat Ts Files

if you want to concat different part of ts files

```sh
ruby ts_concat.rb <output.ts> <input1.ts> <input2.ts> ...
```
