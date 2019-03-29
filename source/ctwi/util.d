module ctwi.util;
import std.stdio, std.path, std.base64, std.string, std.json, std.file;
import twitter4d;

auto uploadMedia(Twitter4D t4d, ubyte[] raw_payload) {
  enum baseUrl = "https://upload.twitter.com/1.1/";
  enum endPoint = "media/upload.json";
  string payload = Base64.encode(raw_payload);

  return t4d.superCustomRequest(baseUrl, "POST", endPoint,
      ["media_data": payload], [
        "Content-type": "application/x-www-form-urlencoded"
      ]);
}

auto updateWithMedia(Twitter4D t4d, string status, string[] media_ids,
    string[string] others = null) {
  auto payload = ["status" : status, "media_ids" : media_ids.join(",")];
  foreach (key, val; others) {
    payload[key] = val;
  }

  return t4d.request("POST", "statuses/update.json", payload);
}
