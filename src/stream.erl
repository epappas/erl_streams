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
-vsn("0.0.1").

-include("erl_streams_commons.hrl").

%% API
-export([
  new/0,
  new/1,
  new/2,
  from_list/1,
  pause/1,
  drain/1,
  put/2,
  put_with_delay/3,
  put_from_list/2,
  put_while/2,
  take/1,
  take/2,
  take_with_delay/2,
  take_and_pause/1,
  take_while/2,
  resume/1,
  drop/1,
  drop_while/2,
  filter/2,
  map/2,
  reduce/2,
  reduce/3,
  zip/2,
  is_empty/1,
  is_dropping/1
]).

-spec(new() -> #stream{}).
new() -> new(new_stream).

-spec(new(Name :: term()) -> #stream{}).
new(Name) ->
  #stream{name = Name}.

-spec(new(Name :: term(), Max :: number()) -> #stream{}).
new(Name, Max) ->
  #stream{name = Name, max_buffer = Max}.

-spec(from_list(List :: iolist()) -> #stream{}).
from_list(List) ->
  Stream = new(from_list),
  {ok, NewStream} = stream:put_from_list(Stream, List),
  NewStream.

-spec(pause(Stream :: #stream{}) -> #stream{}).
pause(Stream) -> Stream#stream{is_paused = true}.

-spec(drain(Stream :: #stream{}) -> #stream{}).
drain(_Stream) ->
  #stream{is_paused = false}.

-spec(put(Stream :: #stream{}, Resource :: any()) ->
  {ok, #stream{}} | {paused, #stream{} | {stopped, #stream{}} | {closed, #stream{}}}).
put(#stream{is_paused = true} = Stream, _Resource) ->
  {pause, Stream};
put(#stream{is_stoped = true} = Stream, _Resource) ->
  {stopped, Stream};
put(#stream{is_closed = true} = Stream, _Resource) ->
  {closed, Stream};
put(#stream{buffer = Buffer, max_buffer = MAX} = Stream, _Resource) when length(Buffer) >= MAX ->
  %% a Guard to avoid back pressure
  {pause, Stream#stream{is_paused = true}};

put(#stream{
  is_dropping = true,
  dropping_ctr = DR_Ctr,
  dropping_fn = Dropping_Fn
} = Stream, Resource) ->
  case Dropping_Fn(Stream, Resource) of
  %% if codition no longer exists, retry
    false -> stream:put(resume(Stream), Resource);
  %% stream should keep dropping messages, just raise the counter
    true -> {ok, Stream#stream{
      dropping_ctr = DR_Ctr + 1
    }}
  end;

put(#stream{
  is_paused = false,
  is_stoped = false,
  is_closed = false,
  is_dropping = false
} = Stream, Resource) ->
  {ok, pre_waterfall_tick(Stream, Resource)}.

-spec(put_with_delay(Stream :: #stream{}, Resource :: any(), Delay :: number()) ->
  {'ok', {integer(), reference()}} | {'error', term()}).
put_with_delay(#stream{} = Stream, Resource, Delay) when Delay =:= 0 ->
  timer:apply_after(Delay, stream, put, [Stream, Resource]).

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
  [Value | RestValues] = Buffer,
  {Stream#stream{buffer = RestValues}, Value}.

-spec(take_with_delay(Stream :: #stream{}, Delay :: number()) -> {#stream{}, iolist()}).
take_with_delay(#stream{} = Stream, Delay) ->
  ok = timer:sleep(Delay),
  take(Stream).

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

-spec(resume(Stream :: #stream{}) -> #stream{}).
resume(#stream{} = Stream) ->
  Stream#stream{
    is_dropping = false,
    dropping_ctr = 0,
    dropping_fn = undefined
  }.

-spec(drop(Stream :: #stream{}) -> #stream{}).
drop(#stream{} = Stream) ->
  Stream#stream{
    is_dropping = true,
    dropping_ctr = 0,
    dropping_fn =
    fun(#stream{
      dropping_ctr = DR_Ctr
    } = _ThisStream, _Resource) ->
      DR_Ctr < 1
    end
  }.

-spec(drop_while(Stream :: #stream{}, Fn :: fun()) -> #stream{}).
drop_while(Stream, Dropping_Cond_FN) ->
  Stream#stream{
    is_dropping = true,
    dropping_ctr = 0,
    dropping_fn = Dropping_Cond_FN
  }.

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
reduce(#stream{pre_waterfall = PreWaterfall} = Stream, Fn, Acc) when is_function(Fn) ->
  Stream#stream{
    reduce_acc = Acc,
    pre_waterfall = lists:append(
      PreWaterfall, [[
        {type, reduce},
        {fn, Fn}
      ]]
    )
  }.

-spec(zip(Left :: #stream{}, Right :: #stream{}) -> #stream{}).
zip(#stream{buffer = LBuffer, pre_waterfall = LPRW, post_waterfall = LPOW} = _Left,
    #stream{buffer = RBuffer, pre_waterfall = RPRW, post_waterfall = RPOW} = _Right) ->
  Stream = new(),
  Stream#stream{
    buffer = lists:append(LBuffer, RBuffer),
    pre_waterfall = lists:append(LPRW, RPRW),
    post_waterfall = lists:append(LPOW, RPOW)
  }
.

-spec(is_empty(Stream :: #stream{}) -> boolean()).
is_empty(#stream{buffer = []} = _Stream) -> true;
is_empty(#stream{} = _Stream) -> false.

-spec(is_dropping(Stream :: #stream{}) -> boolean()).
is_dropping(#stream{is_dropping = true} = _Stream) -> true;
is_dropping(#stream{} = _Stream) -> false.

%%%===================================================================
%%% Internal functions
%%%===================================================================

pre_waterfall_tick(#stream{pre_waterfall = PREW} = Stream, Resource) ->
  pre_waterfall_tick(Stream, Resource, PREW).

pre_waterfall_tick(#stream{} = Stream, undefined, _PREW) ->
  Stream;

pre_waterfall_tick(#stream{buffer = Buffer} = Stream, Resource, []) ->
  Stream#stream{
    buffer = lists:append(Buffer, [Resource])
  };

pre_waterfall_tick(#stream{} = Stream, Resource, [Next | RestPREW]) ->

  [Type | RestArgs] = Next,

  {NewStream, NewResource} =
    case Type of
      {type, map} ->
        pre_waterfall_map(Stream, Resource, RestArgs);
      {type, filter} ->
        pre_waterfall_filter(Stream, Resource, RestArgs);
      {type, reduce} ->
        pre_waterfall_reduce(Stream, Resource, RestArgs)
    end,

  pre_waterfall_tick(NewStream, NewResource, RestPREW).

pre_waterfall_map(#stream{buffer = Buffer} = Stream, Resource, [{fn, MapFn}]) ->
  {Stream, MapFn(Resource, Buffer)}.

pre_waterfall_filter(#stream{buffer = Buffer} = Stream, Resource, [{fn, FilterFn}]) ->
  NewResource =
    case FilterFn(Resource, Buffer) of
      true -> Resource;
      _ -> undefined
    end,
  {Stream#stream{}, NewResource}.

pre_waterfall_reduce(#stream{
  reduce_acc = Acc,
  buffer = Buffer
} = Stream, Resource, [{fn, ReduceFn}]) ->

  NewAcc = ReduceFn(Acc, Resource, Buffer),

  {Stream#stream{reduce_acc = NewAcc, buffer = []}, NewAcc}.

