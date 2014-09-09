#!/usr/bin/env escript
%% -*- erlang -*-
%%! -pa ./ebin -pa ./deps/mimetypes/ebin -pa deps/hackney/ebin -pa deps/idna/ebin -pa deps/dispcount/ebin -config async.config

-module(async_disp).

requestHandler(Parent) ->
    % io:format("in loop:Parent:~p:self:~p:~n", [Parent, self()]),
    receive
        %{hackney_response,#Ref<0.0.0.166>,{status,200,<<"OK">>}}
        {hackney_response, _, {status, StatusInt, Reason}} ->
            % io:format("got status: ~p with reason ~p~n", [StatusInt, Reason]),
            requestHandler(Parent);
        {hackney_response, _, {headers, Headers}} ->
            % io:format("got headers: ~p~n", [Headers]),
            % io:format("got headers~n"),
            requestHandler(Parent);
        {hackney_response, Ref, done} ->
            % io:format("got done~n"),
            Parent ! {Ref, done},
            requestHandler(Parent);
            % ok;
        {hackney_response, _, Bin} ->
            % io:format("got chunk: ~p~n", [Bin]),
            % io:format("got chunk~n"),
            requestHandler(Parent);

        % {error, busy} -> 
        %     io:format("got busy~n"),
        %     receiver(Parent);

        % {error, closed} -> 
        %     io:format("got closed~n"),
        %     receiver(Parent);            

        zup ->
            io:format("shutting down~n"),
            ok;

        Else ->
            io:format("else ~p~n", [Else]),
            requestHandler(Parent)
    end.

receiver(Parent) ->
    % io:format("in receive~n"),
    receive
        {_, done} -> 
            io:format("receive done~n"),
            receiver(Parent);
        zup ->
            io:format("shutting down~n"),
            ok;

        {ok, _} ->
            io:format("ok in receiver~n"),
            ok;

        Else ->
            io:format("receiver else ~p~n", [Else]),
            receiver(Parent)

    after 10000 ->
            io:format("timeout in receiver~n"),
            ok
    end.


main(_) ->

    %this can be set here or via the config file see below
    % hackney:start(hackney_disp),
    hackney:start(),
    Self = self(),
    Url = <<"localhost:5984">>,

    ReceiverPid = spawn(fun() -> receiver(Self) end),
    io:format("spawned receiver:~p:~n", [ReceiverPid]),

    % HandlerPid = spawn(fun() -> requestHandler(Self) end),
    HandlerPid = spawn(fun() -> requestHandler(ReceiverPid) end),
    io:format("spawned requestHandler:~p:~n", [HandlerPid]),

    %can set it here or in app's config specified with -config
    %like this
    % [
    %   {hackney, [
    %     {pool_handler, hackney_disp},
    %     {restart, permanent},
    %     {shutdown, 10000},
    %     {maxr, 10},
    %     {maxt, 1},
    %     {timeout, 150000},
    %     {max_connections, 2000}
    %   ]}
    % ].

    % Opts = [async, {stream_to, HandlerPid}, {max_connections, 2000}],
    Opts = [async, {stream_to, HandlerPid}],

    Caller = fun Retry(I) ->
        % io:format("get:~p:~n", [I]),

        % demonstrating the more general request
        % which is a wrapper for the simpler call
        % case hackney:get(Url, [], <<>>, Opts) of
        case hackney:request(get,Url, [], <<>>, Opts) of
            % {ok, _} = hackney:request(get,Url, [], <<>>, Opts)
            {ok, _} -> io:format("ok:~p:~n", [I]);

            {error, Error} ->
                io:format("error:retrying:~p:~p:~n", [I, Error]),
                Retry(I)
        end
    end,
    [ Caller(I2) || I2 <- lists:seq(1, 1000)].
    % receiver(Self).


