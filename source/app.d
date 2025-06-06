import vibe.d;
import pastemyst.auth;

/++
 + Renders an error page, everytime an error occured
 +/
void displayError(HTTPServerRequest req, HTTPServerResponse res, HTTPServerErrorInfo error)
{
    import std.file : append;
    import std.datetime.systime : Clock;

    string errorDebug = "";
    debug errorDebug = error.debugMessage;

    const session = getSession(req);

    if (req.requestPath.startsWith(InetPath("/api")))
    {
        res.contentType = "application/json";
        res.writeBody(`{"statusMessage": "` ~ error.message ~ `"}`);
        return;
    }

    if (error.code == 500)
    {
        auto time = Clock.currTime();
        string msg = "[" ~ time.toSimpleString() ~ "]\n" ~ errorDebug ~ "\n\n";
        append("log", msg);
    }

    res.render!("error.dt", error, errorDebug, session);
}

public void main()
{
	import pastemyst.web : RootWeb, PasteWeb, LoginWeb, UserWeb, UsersWeb, ApiDocsWeb;
	import pastemyst.rest : APIPaste, APITime, APIData, APIUser, APIV1Paste;
	import pastemyst.db : connect, deleteZips;
	import pastemyst.paste : deleteExpiredPastes;
    import pastemyst.auth : deleteExpiredSessions;
    import pastemyst.data : config;
    import vibe.core.log : setLogLevel, LogLevel;

    // 設定日誌級別為 info，確保 logInfo 會被輸出
    setLogLevel(LogLevel.info);

	URLRouter router = new URLRouter();

	// redirect api requests with a trailing slash
	router.any("/*", (HTTPServerRequest req, HTTPServerResponse res) {
		import std.algorithm : startsWith;
		if (req.requestURI.startsWith("/api/") && req.requestURI[$-1] == '/')
		{
			res.redirect(req.requestURI[0..$-1], 307);
		}
	});

	router.registerRestInterface(new APIPaste());
	router.registerRestInterface(new APIUser());
	router.registerRestInterface(new APITime());
	router.registerRestInterface(new APIData());
	router.registerRestInterface(new APIV1Paste());

	router.registerWebInterface(new RootWeb());
	router.registerWebInterface(new ApiDocsWeb());
	router.registerWebInterface(new LoginWeb());
	router.registerWebInterface(new UserWeb());
	router.registerWebInterface(new UsersWeb());
	router.registerWebInterface(new PasteWeb());

	auto fsettings = new HTTPFileServerSettings();
	fsettings.serverPathPrefix = "/static";

	router.get("/static/*", serveStaticFiles("public/", fsettings));

	HTTPServerSettings serverSettings = new HTTPServerSettings();
	serverSettings.bindAddresses = [config.hostIp];
	serverSettings.port = config.hostPort;
	serverSettings.sessionStore = new MemorySessionStore();
	serverSettings.errorPageHandler = toDelegate(&displayError);

	connect();

	setTimer(15.seconds, toDelegate(&deleteExpiredPastes), true);
	setTimer(15.seconds, toDelegate(&deleteExpiredSessions), true);
	setTimer(5.minutes, toDelegate(&deleteZips), true);

	listenHTTP(serverSettings, router);

	runApplication();
}
