import std.stdio;
import std.process;
import std.file, std.path, std.json;
import std.format, std.getopt, std.typecons;
import twitter4d;

struct SettingFile {
  string editor;
  string default_account;
  string[string][string] accounts;
}

SettingFile readSettingFile(string path) {
  if (!exists(path)) {
    throw new Exception("No such a file - %s".format(path));
  }

  SettingFile ret;
  string elem = readText(path);
  auto parsed = parseJSON(elem);

  if ("editor" in parsed.object) {
    ret.editor = parsed.object["editor"].str;
  } else {
    throw new Exception("No such a field - %s".format("editor"));
  }

  if ("default_account" in parsed.object) {
    ret.default_account = parsed.object["default_account"].str;
  } else {
    throw new Exception("No such a field - %s".format("default_account"));
  }

  if ("accounts" in parsed.object) {
    foreach (key, value; parsed.object["accounts"].object) {
      foreach (hk, hv; value.object) {
        ret.accounts[key][hk] = hv.str;
      }
    }
  } else {
    throw new Exception("No such a field - %s".format("accounts"));
  }

  return ret;
}

void main(string[] args) {
  string editor;
  string specified_account;
  string in_reply_to_status_id;
  string favorite;
  string retweet;
  string fav_and_retweet;
  bool no_tweet;
  string follow;
  string remove;

  // dfmt off
  auto helpInformation = getopt(args,
      "editor|e", "specify the editor", &editor,
      "account|a", "specify the account to tweet", &specified_account,
      "in_reply|i", "specify in_reply_to_status_id", &in_reply_to_status_id,
      "favorite|f", "favorite a tweet", &favorite,
      "retweet|r", "retweet a tweet", &retweet,
      "fav_and_rt|fr", "favrote and retweet a tweet", &fav_and_retweet,
      "no-tweet|n", "don't perform tweeting", &no_tweet,
      "follow|fl", "follow the user", &follow,
      "remove|rm", "unfollow the user", &remove
      );
  // dfmt on
  if (helpInformation.helpWanted) {
    defaultGetoptPrinter("Usage:", helpInformation.options);
    return;
  }

  string setting_file_path;
  auto xdg_config_home = environment.get("XDG_CONFIG_HOME") ~ "/ctwi";
  enum alphakai_dir = "~/.myscripts/ctwi";
  enum default_dir = "~/.config/ctwi";
  string setting_file_name = "setting.json";
  immutable setting_file_search_dirs = [
    xdg_config_home, default_dir, alphakai_dir
  ];
  string dir;
  foreach (_dir; setting_file_search_dirs) {
    immutable path = expandTilde("%s/%s".format(_dir, setting_file_name));
    if (path.exists) {
      setting_file_path = path;
      dir = expandTilde(_dir);
    }
  }

  if (setting_file_path is null) {
    if (!expandTilde(default_dir)) {
      mkdir(expandTilde(default_dir));
    }
    string default_json = `{
  "editor": "your favorite editor",
  "default_account" : "ACCOUNT_NAME1",
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
}`;
    setting_file_path = "%s/%s".format(default_dir, setting_file_name).expandTilde;
    File(setting_file_path, "w").write(default_json);

    writeln("Created dummy setting json file at %s", setting_file_path);
    writeln("Please configure it before use.");
    return;
  }

  SettingFile sf = readSettingFile(setting_file_path);

  if (editor is null) {
    editor = sf.editor;
  }
  if (specified_account is null) {
    specified_account = sf.default_account;
  }

  auto t4d = new Twitter4D(sf.accounts[specified_account]);

  if (fav_and_retweet !is null) {
    favorite = fav_and_retweet;
    retweet = fav_and_retweet;
  }

  if (favorite !is null) {
    t4d.request("POST", "favorites/create.json", ["id": favorite]);
  }

  if (retweet !is null) {
    t4d.request("POST", "statuses/retweet/%s.json".format(retweet), [
        "id": retweet
        ]);
  }

  if (follow !is null) {
    t4d.request("POST", "friendships/create.json", ["screen_name": follow]);
  }

  if (remove !is null) {
    t4d.request("POST", "friendships/destroy.json", ["screen_name": remove]);
  }

  if (no_tweet) {
    return;
  }

  string file_name = "tmp_tweet_file";
  string file_path = "%s/%s".format(dir, file_name);

  auto pid = spawnProcess([editor, "%s".format(file_path)]);
  wait(pid);

  if (exists(file_path)) {
    string tweet_elem = readText(file_path);

    remove(file_path);

    if (in_reply_to_status_id is null) {
      t4d.request("POST", "statuses/update.json", ["status": tweet_elem]);
    } else {
      auto parsed = parseJSON(t4d.request("GET",
          "statuses/show/%s.json".format(in_reply_to_status_id)));

      if ("user" in parsed.object) {
        string replay_target_screen_name = "@%s".format(
            parsed.object["user"].object["screen_name"].str);

        tweet_elem = "%s %s".format(replay_target_screen_name, tweet_elem);

        t4d.request("POST", "statuses/update.json", [
            "status": tweet_elem,
            "in_reply_to_status_id": in_reply_to_status_id
            ]);
      } else {
        throw new Exception("Given Invalid JSON");
      }
    }
  }
}
