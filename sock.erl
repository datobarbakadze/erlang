-module(sock).


-export([get_uri/0,start_server/0,loop_via_proc/2,get_file/0,generate_php/0]).

get_uri() ->
    getUrl("www.google.com",80).

getUrl(Host,Port) -> 
    {ok,Socket} = gen_tcp:connect(Host,Port,[binary,{packet,0}]),
    ok = gen_tcp:send(Socket,"GET / HTTP:1.0\r\n\r\n"),
    get_data(Socket,[]).

get_data(Socket,Data) ->
    receive
        {tcp,Socket,Bin} ->
            get_data(Socket,[Bin,Data]);
        {tcp_closed,Socket} ->
            list_to_binary(lists:reverse(Data))
    end.


start_server() ->
    {ok, Listen} = gen_tcp:listen(34567,[binary,{reuseaddr,true},{active,true}]),
    spawn(fun() -> srv_connect(Listen) end).

srv_connect(Listen) -> 
    {ok, Socket} = gen_tcp:accept(Listen),
    spawn(fun() -> srv_connect(Listen) end),
    loop(Socket).
loop(Socket) ->
    receive
        {tcp,Socket,Bin} ->
            io:format("We have got a binary ~n",[]),
            get_file(),
            {ok, HtmlFile} = file:read_file("tmp.html"),
            Reply = gen_response(HtmlFile),
            io:format("Spawning response process: ~n"),
            _Responser = spawn(fun() -> responser(Socket,Reply) end),
            loop(Socket);
        {tcp_closed,Socket} ->
            io:format("Server has closed the connection ~n")            
    end.
responser(Socket,Data) ->
    io:format("Sending reply ~n"),
    gen_tcp:send(Socket,Data),
    gen_tcp:close(Socket).
get_file() ->
    {ok, File} = file:open("file.html",read),
    {ok, FileToWrite} = file:open("tmp.html",write),
    get_head(File,500 ,0,FileToWrite).

get_head(File, N,CountLine,Tmp) when N>0 ->
    Line = io:get_line(File,''),
    Read = io_lib:format("~s",[Line]),
    case Read of 
        ["<head>\n"] ->
            io:format("We detected head tag~n"),
            io:format(Tmp,"~s~n",["<head>\n\t<style>\n"++ gen_externals(css) ++"\n\t</style>\n\t<script type='text/javascript'>"++ gen_externals(javascript) ++"\n\t</script></head>"]);
        ["<head>"] ->
            io:format("We detected head tag~n"),
            io:format(Tmp,"~s~n",["detected"]);
        "eof" ->
            true;
        _Any ->
            io:format("Rendering other html~n"),
            io:format(Tmp,"~s",[Read])
    end,
    get_head(File,(N-1),(CountLine+1),Tmp);
    % get_head(File,(N-1));
get_head(_,0,_,Tmp) ->
    true.



gen_externals(Script) ->
    case Script of
        javascript ->
            io:format("Processing javascript~n"),
            {ok, File} = file:open("script.js",read);   
        css ->
            io:format("Processing css~n"),
            {ok, File} = file:open("style.css",read)
    end,
    gen_externals(File,"").
gen_externals(ExternalFIle,Conc)->
    Line = io:get_line(ExternalFIle,''),
    Read = io_lib:format("~s",[Line]),
    case Read of
        "eof" ->
            Conc;
        _Any ->
            Conc ++ "\t\t" ++ _Any ++ gen_externals(ExternalFIle,Conc)
    end.
% beginig php generation
generate_php() -> 
    {ok, File} = file:open("file.html",read),
    generate_php(File).
generate_php(PhpFile) -> 
    Line = io:get_line(PhpFile,''),
    Read = io_lib:format("~s",[Line]),
    case Read of
        "eof" ->
            void;
        _any ->
            case Content = re:run(Read,"(<?php)(.*)(?>)",[{capture,first,list}]) of
                nomatch ->
                    contentnomatch,
                    generate_php(PhpFile);
                _Any->
                    {match,PhpContent} = Content,
                    io:format("Php content: ~p ~n",[PhpContent]),
                    case re:run(PhpContent,"[^<?php](.*)[^?>.*]",[{capture,first,list}]) of
                        
                        {match,Phpfunc} ->
                            io:format("php function ~s ~n",[Phpfunc]),
                            io_lib:format("~s",[Phpfunc]),
                            generate_php(PhpFile)
                    end
            end
    end.



gen_response(Str) ->
    io:format("Generating Reply ~n"),
    iolist_to_binary(
    io_lib:fwrite(
    "HTTP/1.0 200 OK\nContent-Type: text/html\ncharset=utf-8\nContent-Length: ~p\n\n~s",
    [size(Str),Str])).



% client side testing code
client_send() ->
    {ok, Socket} = gen_tcp:connect("localhost",34567,[binary,{packet,4}]),
    Socket.

client_send(Str,Socket) ->
    ok = gen_tcp:send(Socket,term_to_binary(Str)),
    receive
        {tcp,Socket,Bin} ->
            io:format("We are receiving the folowing binary data: ~p ~n",[Bin]),
            Cterm = binary_to_term(Bin),
            io:format("We received following data ~p ~n",[Cterm])
    end.
client_loop(Str,Count) ->
    Socket = client_send(),
    client_loop(Socket,Count,Str).
client_loop(Socket,N,Str) when N>0 ->
    client_send(Str,Socket),
    client_loop(Socket,(N-1),Str);

client_loop(_,0,_) ->
    true.

loop_via_proc(Str,Count) ->
    spawn(fun() -> client_loop(Str,Count) end).
    