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
  etap:plan(3),
  Stream = stream:new(),
  #stream{name = Name} = Stream,

  %% Basic dummy tests
  etap:is(Name =:= new_stream, true, "Anonymous Stream is named correctly"),
  etap:is(stream:is_empty(Stream), true, "New Streams should be empty"),

  %% TEST list insertion
  {ok, Stream0} = stream:put_from_list(Stream, [1, 2, 3]),

  {Stream1, A} = stream:take(Stream0),
  {Stream2, B} = stream:take(Stream1),
  {_Stream3, C} = stream:take(Stream2),

  etap:is([A, B, C], [1,2,3], "Take should get the elements from the inserted list"),

  etap:end_tests(),
  ok.