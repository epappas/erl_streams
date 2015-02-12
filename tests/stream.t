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
  etap:plan(4),
  Stream = stream:new(),
  #stream{name = Name} = Stream,

  %% Basic dummy tests
  etap:is(Name =:= new_stream, true, "Anonymous Stream is named correctly"),
  etap:is(stream:is_empty(Stream), true, "New Streams should be empty"),

  %% TEST simple put
  {ok, StreamA0} = stream:put(Stream, 0),
  {_StreamA1, AA} = stream:take(StreamA0),

  etap:is(AA, AA, "Simple take and put case"),

  %% TEST list insertion
  {ok, StreamB0} = stream:put_from_list(Stream, [1, 2, 3]),

  {StreamB1, BA} = stream:take(StreamB0),
  {StreamB2, BB} = stream:take(StreamB1),
  {_StreamB3, BC} = stream:take(StreamB2),

  etap:is([BA, BB, BC], [1,2,3], "Take should get the elements from the inserted list"),

  etap:end_tests(),
  ok.