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

  etap:is([BA, BB, BC], [1, 2, 3], "Take should get the elements from the inserted list"),

  test_dropping(),

  test_dropping_while(),

  etap:end_tests(),
  ok.

test_dropping() ->
  Stream = stream:new(),

  {ok, Stream1} = stream:put(Stream, 0),

  Stream2 = stream:drop(Stream1), %% will drop the next one

  etap:is(stream:is_dropping(Stream2), true, "Stream should be in dropping state"),

  {ok, Stream3} = stream:put(Stream2, 1),

  {ok, Stream4} = stream:put(Stream3, 2), %% this action should unblock the stream

  etap:is(stream:is_dropping(Stream4), false, "Stream should escape dropping state after 1 put"),

  #stream{buffer = Buffer} = Stream4,

  etap:is(Buffer, [0, 2], "One message should be missing").

test_dropping_while() ->
  Stream = stream:new(),

  %% Initial put with non dropping condition
  {ok, Stream1} = stream:put(Stream, 0),

  Stream2 = stream:drop_while(Stream1,
    fun(#stream{} = _Stream, Resource) ->
      case Resource of
        5 -> false;
        _ -> true
      end
    end
  ), %% will drop while 5 is not given

  etap:is(stream:is_dropping(Stream2), true, "Stream should be in dropping state"),

  {ok, Stream3} = stream:put_from_list(Stream2, [1, 2, 3, 4, 5, 6, 7, 8, 9]),

  etap:is(stream:is_dropping(Stream3), false, "Stream have stoped dropping"),

  #stream{buffer = Buffer} = Stream3,

  etap:is(Buffer, [0, 5, 6, 7, 8, 9], "All non valid messages should be missing").
