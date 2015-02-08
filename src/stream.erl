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

-module(stream).
-author("epappas").

-include("erl_streams_commons.hrl").

%% API
-export([
  new/1,
  new/2,
  from_list/1,
  pause/1,
  drain/1,
  put/2,
  put_from_list/2,
  put_while/2,
  take/1,
  take/2,
  take_and_pause/1,
  take_while/2,
  drop/1,
  drop_while/2,
  filter/2,
  delay/1,
  delay_while/2,
  map/2,
  reduce/2,
  reduce/3,
  zip/2,
  is_empty/1
]).

-spec(new(Name :: term(), Fn :: fun()) -> #stream{}).
new(Name, Fn) ->
  #stream{name = Name, producer = Fn}.

-spec(new(Fn :: fun()) -> #stream{}).
new(Fn) -> new(new_stream, Fn).

-spec(from_list(List :: iolist()) -> #stream{}).
from_list(List) ->
  new(from_list, fun(#stream{} = Stream) ->
      stream:put_from_list(Stream, List)
    end).

-spec(pause(Stream :: #stream{}) -> #stream{}).
pause(Stream) -> Stream#stream{is_paused = true}.

%% TODO
-spec(drain(Stream :: #stream{}) -> #stream{}).
drain(_Stream) ->
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
    buffer = lists:append(Buffer, [Resource])
  }}.

-spec(put_from_list(Stream :: #stream{}, ResourceList :: list()) ->
  {ok, #stream{}} | {paused, #stream{} | {stopped, #stream{}} | {closed, #stream{}}}).
put_from_list(#stream{} = Stream, ResourceList) when ResourceList =:= [] -> {ok, Stream#stream{}};
put_from_list(#stream{} = Stream, ResourceList) ->
  [H | T] = ResourceList,
  case stream:put(Stream, H) of
    {ok, NewStream} -> stream:put_from_list(NewStream, T);
    OtherState -> OtherState %% closed, isPaused, or anything else
  end.

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
    Resource -> stream:put(Stream#stream{}, Resource)
  end.

-spec(take(Stream :: #stream{}, Number :: number()) -> {#stream{}, list()}).
take(#stream{is_closed = true} = Stream, _Number) -> {Stream, []};
take(#stream{} = Stream, Number) when Number =< 0 -> {Stream, []};
take(#stream{} = Stream, Number) -> take_loop(Stream, Number, []).

take_loop(#stream{} = Stream, 0, SoFar) -> {Stream, SoFar};
take_loop(#stream{buffer = Buffer} = Stream, _Number, SoFar) when Buffer =:= [] -> {Stream, SoFar};
take_loop(#stream{buffer = Buffer} = Stream, Number, SoFar) ->
  [H | T] = Buffer,
  take_loop(Stream#stream{buffer = T}, Number - 1, lists:append(SoFar, H)).

-spec(take(Stream :: #stream{}) -> {#stream{}, iolist()}).
take(#stream{buffer = Buffer} = Stream) when Buffer =:= [] -> {Stream#stream{}, undefined};
take(#stream{buffer = Buffer} = Stream) ->
  [H | T] = Buffer,
  {Stream#stream{buffer = T}, H}.

-spec(take_and_pause(Stream :: #stream{}) -> {#stream{}, iolist()}).
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

%% TODO
-spec(drop(Stream :: #stream{}) -> #stream{}).
drop(_Stream) -> #stream{}.

%% TODO
-spec(drop_while(Stream :: #stream{}, Fn :: fun()) -> #stream{}).
drop_while(_Stream, _Fn) -> #stream{}.

%% TODO
-spec(delay(Stream :: #stream{}) -> #stream{}).
delay(_Stream) -> #stream{}.

%% TODO
-spec(delay_while(Stream :: #stream{}, Fn :: fun()) -> #stream{}).
delay_while(_Stream, _Fn) -> #stream{}.

-spec(filter(Stream :: #stream{}, Fn :: fun()) -> #stream{}).
filter(#stream{pre_waterfall = PreWaterfall} = Stream, Fn) when is_function(Fn) ->
  Stream#stream{
    pre_waterfall = lists:append(
      PreWaterfall, [[{type, filter}, {fn, Fn}]]
    )
  }.

-spec(map(Stream :: #stream{}, Fn :: fun()) -> #stream{}).
map(#stream{pre_waterfall = PreWaterfall} = Stream, Fn) when is_function(Fn) ->
  Stream#stream{
    pre_waterfall = lists:append(
      PreWaterfall, [[{type, map}, {fn, Fn}]]
    )
  }.

-spec(reduce(Stream :: #stream{}, Fn :: fun()) -> #stream{}).
reduce(Stream, Fn) -> reduce(Stream, Fn, undefined).

-spec(reduce(Stream :: #stream{}, Fn :: fun(), Acc :: any()) -> #stream{}).
reduce(#stream{post_waterfall = PostWaterfall} = Stream, Fn, Acc) when is_function(Fn) ->
  Stream#stream{
    post_waterfall = lists:append(
      PostWaterfall, [[
        {type, reduce},
        {fn, Fn},
        {acc, Acc}
      ]]
    )
  }.

%% TODO
-spec(zip(Left :: #stream{}, Right :: #stream{}) -> #stream{}).
zip(#stream{} = _Left, #stream{} = _Right) ->
  new(fun(#stream{} = Stream) ->
    Stream
  end).

-spec(is_empty(Stream :: #stream{}) -> boolean()).
is_empty(#stream{buffer = []} = _Stream) -> true;
is_empty(#stream{} = _Stream) -> false.
