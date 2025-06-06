module pastemyst.paste.create;

import vibe.d;
import pastemyst.data;

/++
 + creates a paste, to be used in web and rest interfaces
 + it validates the data but doesn't insert into the db
 +/
public Paste createPaste(string title, string expiresIn, Pasty[] pasties, bool isPrivate, string ownerId) @safe
{
    import pastemyst.encoding : randomBase36Id;
    import pastemyst.conv : valueToEnum;
    import std.typecons : Nullable;
    import std.datetime : Clock;
    import pastemyst.db : insert, findOneById;
    import pastemyst.data : Paste, getLanguageName;
    import pastemyst.util : generateUniqueId;
    import std.uni : toLower;
    import pastemyst.time : expiresInToUnixTime;
    import std.array : replace;

    enforceHTTP(!pasties.length == 0, HTTPStatus.badRequest, "pastie arrays has to have at least one element.");

    Nullable!ExpiresIn expires = valueToEnum!ExpiresIn(expiresIn);

    enforceHTTP(!expires.isNull, HTTPStatus.badRequest, "invalid expiresIn value.");

    enforceHTTP(!isPrivate || ownerId != "", HTTPStatus.forbidden, "can't create a private paste if not logged in");

    foreach (ref pasty; pasties)
    {
        pasty.language = getLanguageName(pasty.language);
        enforceHTTP(!(pasty.language is null), HTTPStatus.badRequest, "invalid language value.");
    }

    auto currentTime = Clock.currTime().toUnixTime();

    ulong deletesAt = 0;

    if (expires.get() != ExpiresIn.never)
    {
        deletesAt = expiresInToUnixTime(currentTime, expires.get());
    }

    Paste paste;
    paste.id = generateUniqueId!Paste();
    paste.createdAt = currentTime;
    paste.expiresIn = expires.get();
    paste.deletesAt = deletesAt;
    paste.title = title;
    paste.ownerId = ownerId;
    paste.isPrivate = isPrivate;
    paste.encrypted = false;

    foreach (pasty; pasties)
    {
        pasty.id = generateUniquePastyId(paste);

        if (pasty.language.toLower() == "autodetect")
        {
            pasty.language = autodetectLanguage(paste.id, pasty);
        }

        pasty.code = pasty.code.replace("\r\n", "\n");

        paste.pasties ~= pasty;
    }

    return paste;
}

/++
 + creates an encrypted pastes
 +/
public EncryptedPaste createEncryptedPaste(string title, string expiresIn, Pasty[] pasties, bool isPrivate,
        string ownerId, string password) @trusted
{
    
    import pastemyst.encoding : randomBase36Id;
    import pastemyst.conv : valueToEnum;
    import std.typecons : Nullable;
    import std.datetime : Clock;
    import pastemyst.db : insert, findOneById;
    import pastemyst.util : generateUniqueId;
    import std.uni : toLower;
    import pastemyst.time : expiresInToUnixTime;
    import std.array : replace;
    import crypto.aes : AESUtils, AES256;
    import crypto.padding : PaddingMode;
    import csprng.system : CSPRNG;
    import scrypt.password : genScryptPasswordHash, SCRYPT_OUTPUTLEN_DEFAULT, SCRYPT_R_DEFAULT, SCRYPT_P_DEFAULT;

    enforceHTTP(!pasties.length == 0, HTTPStatus.badRequest, "pasties array has to have at least one element.");

    Nullable!ExpiresIn expires = valueToEnum!ExpiresIn(expiresIn);

    enforceHTTP(!expires.isNull, HTTPStatus.badRequest, "invalid expiresIn value.");

    enforceHTTP(!isPrivate || ownerId != "", HTTPStatus.forbidden, "can't create a private paste if not logged in");

    foreach (pasty; pasties)
    {
        pasty.language = getLanguageName(pasty.language);
        enforceHTTP(!(pasty.language is null), HTTPStatus.badRequest, "invalid language value.");
    }

    auto currentTime = Clock.currTime().toUnixTime();

    ulong deletesAt = 0;

    if (expires.get() != ExpiresIn.never)
    {
        deletesAt = expiresInToUnixTime(currentTime, expires.get());
    }

    EncryptedPaste paste;
    paste.id = generateUniqueId!Paste();
    paste.createdAt = currentTime;
    paste.expiresIn = expires.get();
    paste.deletesAt = deletesAt;
    paste.ownerId = ownerId;
    paste.isPrivate = isPrivate;
    paste.encrypted = true;

    // used so we can generate unique ids for pasties
    Paste mockPaste;
    mockPaste.id = paste.id;

    EncryptedPasteData data;

    data.title = title;

    foreach (pasty; pasties)
    {
        pasty.id = generateUniquePastyId(mockPaste);

        if (pasty.language.toLower() == "autodetect")
        {
            pasty.language = autodetectLanguage(paste.id, pasty);
        }

        pasty.code = pasty.code.replace("\r\n", "\n");

        data.pasties ~= pasty;
        mockPaste.pasties ~= pasty;
    }

    auto dataJson = cast(ubyte[]) serializeToJsonString(data);

    ubyte[] key = cast(ubyte[]) (new CSPRNG()).getBytes(32);
    ubyte[16] iv = 0;

    auto encryptedData = AESUtils.encrypt!AES256(dataJson, cast(const(char[])) key, iv, PaddingMode.PKCS5);

    paste.encryptedData = cast(string) encryptedData;

    string salt = cast(string) (new CSPRNG).getBytes(16);

    paste.salt = salt;

    string passwordHash = genScryptPasswordHash(password, salt, SCRYPT_OUTPUTLEN_DEFAULT,
           524_288, SCRYPT_R_DEFAULT, SCRYPT_P_DEFAULT);

    auto encryptedKey = AESUtils.encrypt!AES256(key, passwordHash, iv, PaddingMode.PKCS5);

    paste.encryptedKey = cast(string) encryptedKey;

    return paste;
}

/++
 + tries to autodetect a language, will try and get the language from the pasty title first
 +/
private string autodetectLanguage(string pasteId, Pasty pasty) @safe
{    import std.path : extension;
    import pastemyst.data : languages;
    import vibe.http.client : requestHTTP, HTTPMethod;
    import vibe.data.json : Json, parseJsonString;
    import std.conv : to;
    import vibe.core.log : logInfo, logError;

    // check if the language can be gotten from the extension
    auto ext = extension(pasty.title);
    if (ext !is null)
    {
        auto extLang = getLanguageName(ext[1..$]);
        if (extLang !is null) return extLang;
    }

    string lang = "Plain Text";

    try
    {
        // 創建 API 請求的 JSON 資料
        Json requestData = Json.emptyObject;
        requestData["text"] = pasty.code;
        requestData["verbose"] = false;
        requestData["fineTune"] = false;
        requestData["expectedRelativeConfidence"] = 0.2;

        // 呼叫語言檢測 API
        requestHTTP("http://192.168.0.123:8787/guess",
            (scope req) {
                req.method = HTTPMethod.POST;
                req.headers["Content-Type"] = "application/json";
                req.writeJsonBody(requestData);
            },
            (scope res) {
                if (res.statusCode == 200)
                {
                    auto responseJson = res.readJson();
                    if ("languageId" in responseJson)
                    {
                        string langId = responseJson["languageId"].get!string;
                        // 嘗試將 languageId 轉換為完整的語言名稱
                        auto fullLangName = getLanguageName(langId);
                        if (fullLangName !is null)
                        {
                            lang = fullLangName;
                        }
                        else
                        {
                            lang = langId;
                        }
                    }
                }
            }
        );    }
    catch(Exception e) {
        // 如果 API 呼叫失敗，返回預設值
        logError("Language detection API failed: %s", e.msg);
        lang = "Plain Text";
    }

    logInfo("Autodetected language for paste %s: %s", pasteId, lang);
    
    // 備用方案：如果需要使用 writeln，請加上手動刷新
    // import std.stdio : writeln, stdout;
    // writeln("Autodetected language for paste ", pasteId, ": ", lang);
    // stdout.flush(); // 強制刷新輸出緩衝區
    
    return lang;
}
