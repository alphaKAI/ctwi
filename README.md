# ctwi
Command line tweet tool

## Requirements

* Latest DMD
* Latest dub
* Twitter ConsumerKey/Secret & AccsessToken/Secret

## Installation

```
$ git clone https://github.com/alphaKAI/ctwi
$ cd ctwi
$ dub build
```

## Usage

At first, Please make a setting file as follows:  

```json
{
  "editor": "vim",
  "default_account":"ACCOUNT_NAME1",
  "accounts" : {
    "ACCOUNT_NAME1": {
      "consumerKey"       : "Your consumer key for ACCOUNT_NAME1",
      "consumerSecret"    : "Your consumer secret for ACCOUNT_NAME1",
      "accessToken"       : "Your access token for ACCOUNT_NAME1",
      "accessTokenSecret" : "Your access token secret for ACCOUNT_NAME1"
    },
    "ACCOUNT_NAME2" : {
      "consumerKey"       : "Your consumer key for ACCOUNT_NAME2",
      "consumerSecret"    : "Your consumer secret for ACCOUNT_NAME2",
      "accessToken"       : "Your access token for ACCOUNT_NAME2",
      "accessTokenSecret" : "Your access token secret for ACCOUNT_NAME2"
    }
  }
}
```

Then,
```
$ ./ctwi
```

## Useful Options

- --acount some_account or -a some_account : use some_account instead of default_account
- --in_reply tweet_id or -i tweet_id : you can reply to a tweet with specifying tweet_id of the tweet. @screen_name of target is  automatically complemented.
- --favorite tweet_id or -f tweet_id : favorite the tweet
- --retweet tweet_id or -r tweet_id : retweet the tweet
- --fav_and_rt tweet_id or -fr tweet_id : favorite and retweet the tweet
- --follow screen_name or -fl screen_name : follow the user
- --remove screen_name of -rm screen_name : unfollow the user

## LICENSE
ctwi is released under the MIT License.  
Copyright (C) 2019, Akihiro Shoji