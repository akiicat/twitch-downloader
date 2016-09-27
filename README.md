# TwitchDown
Usage Twitch API to download vedio.

## Usage
### Get Client ID
[Register your Application](https://www.twitch.tv/kraken/oauth2/clients/new)

and Modify client_id to your client_id

```ruby
# vedio.rb
client_id = ''
client_id = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
```

### Download vod

```sh
ruby download.rb <url>
```

## Tools
### Concat Ts Files

if you want to concat different part of ts files

```sh
ruby ts_concat.rb <output.ts> <input1.ts> <input2.ts> ...
```
