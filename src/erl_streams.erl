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
  #stream{}.

-spec(new(Fn :: fun()) -> #stream{}).
new(Fn) -> #stream{}.

-spec(from_list(List :: iolist()) -> #stream{}).
from_list(List) -> #stream{}.

-spec(pause(Stream :: #stream{}) -> #stream{}).
pause(Stream) -> Stream#stream{is_paused = true}.

-spec(drain(Stream :: #stream{}) -> #stream{}).
drain(Stream) -> #stream{}.

-spec(put(Stream :: #stream{}, Resource :: any()) ->
  {ok, #stream{}} | {paused, #stream{} | {closed, #stream{}}}).
put(Stream, Resource) -> {ok, #stream{}}.

-spec(put(Stream :: #stream{}, Fn :: fun()) -> #stream{}).
put_while(Stream, Fn) -> #stream{}.

-spec(take(Stream :: #stream{}, Number :: number()) -> list()).
take(Stream, Number) -> [<<"">>].

-spec(take(Stream :: #stream{}) -> binary()).
take(Stream) -> <<"">>.

-spec(take_until(Stream :: #stream{}, Fn :: fun()) -> binary()).
take_until(Stream, Fn) -> <<"">>.

-spec(take_while(Stream :: #stream{}, Fn :: fun()) -> binary()).
take_while(Stream, Fn) -> <<"">>.

-spec(take_and_pause(Stream :: #stream{}) -> {Stream, binary()}).
take_and_pause(Stream) -> {Stream, <<"">>}.

-spec(filter(Stream :: #stream{}, Fn :: fun()) -> #stream{}).
filter(Stream, Fn) -> #stream{}.

-spec(drop(Stream :: #stream{}) -> #stream{}).
drop(Stream) -> #stream{}.

-spec(drop_while(Stream :: #stream{}, Fn :: fun()) -> #stream{}).
drop_while(Stream, Fn) -> #stream{}.

-spec(drop_until(Stream :: #stream{}, Fn :: fun()) -> #stream{}).
drop_until(Stream, Fn) -> #stream{}.

-spec(delay(Stream :: #stream{}) -> #stream{}).
delay(Stream) -> #stream{}.

-spec(delay_until(Stream :: #stream{}, Fn :: fun()) -> #stream{}).
delay_until(Stream, Fn) -> ok.

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
is_empty(#stream{buffer = []} = Stream) -> true;

is_empty(#stream{} = Stream) -> false.

%%%===================================================================
%%% Internal functions
%%%===================================================================
