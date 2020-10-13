-module(brod).
-compile(export_all).

send(SomeList,Port) ->
    case inet:ifget("eth0", [broadaddr]) of
        {ok, [{broadaddr,Ip}]} ->
            {ok, Socket} = gen_udp:open(45000,[{broadcast, true}]),
            gen_udp:send(Socket,Ip,Port,SomeList),
            gen_udp:close(Socket),
            io:format("~p ~n",[SomeList]);
        _ ->
            io:format("Somthing's wrong ~n")
    end.
    
as_proc() ->
    spawn(node(), brod, listen,[]).
    
listen() ->
    {ok, Socket} = gen_udp:open(44002),
    loop(Socket).

loop(Socket) ->
    receive
        {udp,Port,Ip,Through,Msg} = Any ->
            io:format("~p:~p> ~p ~n",[Ip,Through,Msg]),
            loop(Socket)
    end.