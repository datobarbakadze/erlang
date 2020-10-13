-module(kvs).

-export([start/0,store/2,lookup/1]).

% greatest code ever
start() ->
    register(kvs,spawn(fun() ->loop() end)).


store(Key,Value) -> 
    rpc({store,Key,Value}).

lookup(Key) -> 
    rpc({lookup,Key}).

rpc(Request) ->
    kvs ! {self(),Request},
    receive
        {kvs, Response} ->
            Response
    end.
loop() ->
    receive 
        {From, {store,Key, Value}} ->
            put(Key, Value),
            From ! {kvs,{stored}},
            io:format("We have stored the value {~p : ~p} in process dictionary ~n", [Key,Value]),
            loop();
        {From,{lookup,Key}} ->
            Kval = get(Key),
            io:format("We have sent you a value of ~p ~n",[Key]),
            From ! {kvs,Kval},
            loop()
    end.
    