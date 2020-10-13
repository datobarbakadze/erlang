-module(server).

-export([start_me_up/3,store/2]).

% greatest code ever
start_me_up(MM, _Argsc,_ArgS) ->
    loop(MM).


store(Key,Value) -> 
    rpc({store,Key,Value}).

rpc(Request) ->
    kvs ! {self(),Request},
    receive
        {kvs, Response} ->
            Response
    end.
loop(MM) ->
    receive 
        {chan,MM, {store,Key, Value}} ->
            kvs:store(Key,Value),
            io:format("We have stored the value {~p : ~p} in process dictionary ~n", [Key,Value]),
            loop(MM);
        {chan,MM,{lookup,Key}} ->
            MM ! {send,kvs:lookup(Key)},
            io:format("We have sent you a value of ~p ~n",[Key]),
            loop(MM);
        {chan_closed, MM} -> 
            true
    end.
    