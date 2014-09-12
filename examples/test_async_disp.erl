#!/usr/bin/env escript
%% -*- erlang -*-
%%! -pa ./ebin -pa ./deps/mimetypes/ebin -pa deps/hackney/ebin -pa deps/idna/ebin -pa deps/dispcount/ebin

-module(test_async).
% -export([loop/0]).




main(_) ->
    hackney:start(hackney_disp),

    Url = <<"https://friendpaste.com/_all_languages">>,
    Loop = fun MyLoop() ->
        io:format("in loop~n"),
        receive
            %{hackney_response,#Ref<0.0.0.166>,{status,200,<<"OK">>}}
            {hackney_response, _, {status, StatusInt, Reason}} ->
                io:format("got status: ~p with reason ~p~n", [StatusInt, Reason]),
                MyLoop();
            {hackney_response, _, {headers, Headers}} ->
                io:format("got headers: ~p~n", [Headers]),
                MyLoop();
            {hackney_response, _, done} ->
                ok;
            {hackney_response, _, Bin} ->
                io:format("got chunk: ~p~n", [Bin]),
                MyLoop();

            zup ->
                io:format("shutting down~n"),
                ok;

            Else ->
                io:format("else ~p~n", [Else]),
                MyLoop()
            end
    end,
    Looper = spawn(Loop),
    io:format("spawned Looper:~p:~n", [Looper]),
    receive
        after 2000 -> ok
    end,
    Opts = [async, {stream_to, Looper}],
    Launcher = fun (Index) -> io:format("sending msg:~p:~n", [Index]), {ok, _} = hackney:get(Url, [], <<>>, Opts) end,
    % [ Launcher(I) || I <- lists:seq(1, 2)],
    Launcher(1),
    Looper ! zup,
    receive
        after 2000 -> ok
    end.

