#!/usr/bin/env escript
%%% -*- erlang -*-
%%! -pa ./ebin -pa ./tests
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

-include("../src/erl_streams_commons.hrl").

main(_) ->
  etap:plan(unknown),

  test_simple_start(),
  test_callbacks(),

  etap:end_tests(),
  ok.

test_simple_start() ->
  {ok, StreamPID} = gen_stream:start(simple_stream, simple_stream, [test]),

  #stream{
    mod = Mod,
    mod_state = State
  } = gen_stream:get_stream(StreamPID),

  etap:is(Mod, simple_stream, "new Stream should own simple_stream"),
  etap:is(State, [test], "new Stream should have correct state").

test_callbacks() ->
  {ok, StreamPID} = gen_stream:start(simple_stream, simple_stream, [test]),

  etap:is_ok(gen_stream:put(StreamPID, test), "gen_stream:put should return ok"),

  etap:is(gen_stream:take(StreamPID), {ok, 1}, "gen_stream:take should take the modified resource").
