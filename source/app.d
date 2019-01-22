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

  auto helpInformation = getopt(args, "editor|e", "specify the editor",
      &editor, "account|a", "specify the account to tweet", &specified_account);
  if (helpInformation.helpWanted) {
    defaultGetoptPrinter("Usage:", helpInformation.options);
    return;
  }

  string dir = expandTilde("~/.myscripts/ctwi");
  string setting_file_name = "setting.json";
  SettingFile sf = readSettingFile("%s/%s".format(dir, setting_file_name));

  if (editor is null) {
    editor = sf.editor;
  }
  if (specified_account is null) {
    specified_account = sf.default_account;
  }

  string file_name = "tmp_tweet_file";
  string file_path = "%s/%s".format(dir, file_name);

  auto pid = spawnProcess([editor, "%s".format(file_path)]);
  wait(pid);

  string tweet_elem = readText(file_path);

  remove(file_path);

  auto t4d = new Twitter4D(sf.accounts[specified_account]);

  t4d.request("POST", "statuses/update.json", ["status" : tweet_elem]);
}
