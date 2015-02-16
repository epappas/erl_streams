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
  etap:plan(12),

  {ok, StreamPID} = gen_stream:start(test),

  #stream{} = gen_stream:get_stream(StreamPID),

  etap:is(gen_stream:is_open(StreamPID), true, "new gen_streamshould be open"),

  etap:is(gen_stream:is_empty(StreamPID), true, "new gen_streamshould be empty"),

  etap:is_ok(gen_stream:put(StreamPID, 1), "gen_stream:put should return ok"),

  etap:is(gen_stream:take(StreamPID), {ok, 1},"gen_stream:take should pop the buffer"),

  etap:is(gen_stream:take(StreamPID), {ok, undefined},"gen_stream:take should pop undefined"),

  etap:is_ok(gen_stream:pause(StreamPID), "gen_stream:pause should return ok"),

  etap:is(gen_stream:put(StreamPID, test), {error, pause}, "paused stream should return {error, pause} on put"),

  etap:is_ok(gen_stream:drain(StreamPID), "gen_stream:drain should return ok"),

  etap:is_ok(gen_stream:drain(StreamPID), "gen_stream:drain should return ok no matter what state"),

  etap:is_ok(gen_stream:put(StreamPID, 1), "gen_stream:put should return ok after drain"),

  etap:is(gen_stream:take_and_pause(StreamPID), {ok, 1}, "gen_stream:take_and_pause should pop the buffer"),

  etap:is(gen_stream:is_paused(StreamPID), true, "gen_stream:take_and_pause should pause the stream"),

  gen_stream:drain(StreamPID), %% unpause it

  etap:end_tests(),
  ok.