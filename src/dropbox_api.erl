-module('dropbox_api').

%% API exports
%%-export([]).
-compile(export_all).

%%====================================================================
%% API functions
%%====================================================================

%% Upload file

upload(LFname,RFname,Client) when is_list(LFname) ->
	case file:read_file(LFname) of
		{ok,LBin} -> upload(LBin,RFname,Client);
		{error, Reason}	-> {error,0,Reason}
	end;	

upload(LBin,RFname,Client) when is_binary(LBin) ->
	Uri = "https://content.dropboxapi.com/1/files_put/auto/",
	Body = LBin,
	Params =  [{"overwrite",true},{"autorename",true}],
	Url = restc:construct_url(Uri,RFname,Params),
	Headers = {"Content-Length",size(LBin)},
	case oauth2c:request(put, json, Url, [200], Headers, Body, Client) of
		{{ok,200,RHeaders,Replay},Client2} -> {ok,Replay};
		{{error,409,_,_},_} -> {error,409,"The call failed because a conflict occurred."};
		{{error,411,_,_},_} -> {error,411,"Missing Content-Length header."};
		{{error,Err,_,Replay},_} -> {error,Err,Replay}
	end.

%% Make dir

make_dir(Path,Client) when is_list(Path) ->
	Uri = "https://api.dropboxapi.com/1/fileops/create_folder",
	Params =  [{"root","auto"},{"path",Path}],
	Url = restc:construct_url(Uri,Params),
	case oauth2c:request(post, json, Url, [200], Client) of
		{{ok,200,RHeaders,Replay},Client2} -> {ok,Replay};
		{{error,403,_,_},_} -> {error,403,"There is already a folder at the given destination."};
		{{error,Err,_,Replay},_} -> {error,Err,Replay}
	end.

% Account info

account_info(Client) ->
	Uri = "https://api.dropboxapi.com/1/account/info",
	case oauth2c:request(get, Uri, [200], Client) of
		{{ok,200,RHeaders,Replay},Client2} -> {ok,Replay};
		{{error,Err,_,Replay},_} -> {error,Err,Replay}
	end.


%%====================================================================
%% Internal functions
%%====================================================================
