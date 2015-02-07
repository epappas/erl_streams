%%% -*- erlang -*-
%%%-------------------------------------------------------------------
%%% @author Evangelos Pappas <epappas@evalonlabs.com>
%%% @copyright (C) 2015, evalonlabs
%%% The MIT License (MIT)
%%%
%%% Copyright (c) 2015 Evangelos Pappas
%%%
%%% Permission is hereby granted, free of charge, to any person obtaining a copy
%%% of this software and associated documentation files (the "Software"), to deal
%%% in the Software without restriction, including without limitation the rights
%%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%%% copies of the Software, and to permit persons to whom the Software is
%%% furnished to do so, subject to the following conditions:
%%%
%%% The above copyright notice and this permission notice shall be included in all
%%% copies or substantial portions of the Software.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
%%% SOFTWARE.
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(erl_streams).
-author("epappas").

-behaviour(application).

-include("erl_streams_commons.hrl").

%% Application callbacks
-export([
  start/2,
  stop/1
]).

%%%===================================================================
%%% Application callbacks
%%%===================================================================

-spec(start(StartType :: normal | {takeover, node()} | {failover, node()},
    StartArgs :: term()) ->
  {ok, pid()} |
  {ok, pid(), State :: term()} |
  {error, Reason :: term()}).
start(_StartType, _StartArgs) ->
  case streams_sup:start_link() of
    {ok, Pid} ->
      {ok, Pid};
    Error ->
      Error
  end.

-spec(stop(State :: term()) -> term()).
stop(_State) ->
  ok.

-spec(new(Name :: term(), Fn :: fun()) -> #stream{}).
new(Name, Fn) ->
  #stream{name = Name, producer = Fn}.

-spec(new(Fn :: fun()) -> #stream{}).
new(Fn) -> new(0, Fn).

-spec(from_list(List :: iolist()) -> #stream{}).
from_list(List) -> #stream{}.

-spec(pause(Stream :: #stream{}) -> #stream{}).
pause(Stream) -> Stream#stream{is_paused = true}.

-spec(drain(Stream :: #stream{}) -> #stream{}).
drain(Stream) ->
  #stream{is_paused = false}.

-spec(put(Stream :: #stream{}, Resource :: any()) ->
  {ok, #stream{}} | {paused, #stream{} | {stopped, #stream{}} | {closed, #stream{}}}).
put(#stream{is_paused = false} = Stream, _Resource) ->
  {pause, Stream};
put(#stream{is_stoped = false} = Stream, _Resource) ->
  {stopped, Stream};
put(#stream{is_closed = true} = Stream, _Resource) ->
  {closed, Stream};

put(#stream{
  is_paused = false,
  is_stoped = false,
  is_closed = false,
  buffer = Buffer
} = Stream, Resource) ->
  {ok, Stream#stream{
    buffer = lists:append(Buffer,[Resource])
  }}.

-spec(put_while(Stream :: #stream{}, Fn :: fun()) ->
  {ok, #stream{}} | {paused, #stream{} | {stopped, #stream{}} | {closed, #stream{}}}).

put_while(#stream{is_paused = false} = Stream, _Fn) ->
  {pause, Stream};
put_while(#stream{is_stoped = false} = Stream, _Fn) ->
  {stopped, Stream};
put_while(#stream{is_closed = true} = Stream, _Fn) ->
  {closed, Stream};

put_while(#stream{
  is_paused = false,
  is_stoped = false,
  is_closed = false
} = Stream, Fn) when is_function(Fn) ->
  case Fn(Stream) of
    undefined -> {ok, Stream};
    Resource -> put(Stream, Resource)
  end.

-spec(take(Stream :: #stream{}, Number :: number()) -> {#stream{}, list()}).
take(#stream{is_closed = true} = Stream, _Number)-> {Stream, []};
take(#stream{is_closed = true} = Stream, _Number)-> {Stream, []};
take(#stream{} = Stream, Number) when Number =< 0 -> {Stream, []};
take(#stream{} = Stream, Number) -> take_loop(Stream, Number, []).

take_loop(#stream{} = Stream, 0, SoFar) -> {Stream, SoFar};
take_loop(#stream{buffer = Buffer} = Stream, _Number, SoFar) when Buffer =:= [] -> {Stream, SoFar};
take_loop(#stream{buffer = Buffer} = Stream, Number, SoFar) ->
  [H | T] = Buffer,
  take_loop(Stream#stream{buffer = T}, Number - 1, lists:append(SoFar, H)).

-spec(take(Stream :: #stream{}) -> {#stream{}, iolist()}).
take(#stream{buffer = Buffer} = _Stream) when Buffer =:= [] -> {#stream, undefined};
take(#stream{buffer = Buffer} = Stream) ->
  [H | T] = Buffer,
  {Stream#stream{buffer = T}, H}.

-spec(take_and_pause(Stream :: #stream{}) -> {Stream, iolist()}).
take_and_pause(#stream{} = Stream) ->
  {NewStream, Resource} = take(Stream),
  {NewStream#stream{is_paused = true}, Resource}.

-spec(take_while(Stream :: #stream{}, Fn :: fun()) -> #stream{}).
take_while(Stream, Fn) ->
  {NewStream, Resource} = take(Stream),
  case Fn(Resource) of
    true -> take_while(NewStream, Fn);
    false -> NewStream
  end.

-spec(filter(Stream :: #stream{}, Fn :: fun()) -> #stream{}).
filter(Stream, Fn) -> #stream{}.

-spec(drop(Stream :: #stream{}) -> #stream{}).
drop(Stream) -> #stream{}.

-spec(drop_while(Stream :: #stream{}, Fn :: fun()) -> #stream{}).
drop_while(Stream, Fn) -> #stream{}.

-spec(delay(Stream :: #stream{}) -> #stream{}).
delay(Stream) -> #stream{}.

-spec(delay_while(Stream :: #stream{}, Fn :: fun()) -> #stream{}).
delay_while(Stream, Fn) -> #stream{}.

-spec(map(Stream :: #stream{}, Fn :: fun()) -> #stream{}).
map(Stream, Fn) -> #stream{}.

-spec(reduce(Stream :: #stream{}, Fn :: fun()) -> #stream{}).
reduce(Stream, Fn) -> reduce(Stream, Fn, undefined).

-spec(reduce(Stream :: #stream{}, Fn :: fun(), Acc :: any()) -> #stream{}).
reduce(Stream, Fn, Acc) -> #stream{}.

-spec(zip(Left, Right) -> #stream{}).
zip(Left, Right) -> #stream{}.

-spec(is_empty(Stream :: #stream{}) -> boolean()).
is_empty(#stream{buffer = []} = _Stream) -> true;
is_empty(#stream{} = _Stream) -> false.

%%%===================================================================
%%% Internal functions
%%%===================================================================
