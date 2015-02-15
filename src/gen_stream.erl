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

-module(gen_stream).
-author("epappas").
-vsn("0.0.1").

-behaviour(gen_fsm).

-include("./erl_streams_commons.hrl").

%% API
-export([
  start/1,
  start_link/0,
  start_link/4,
  put/2,
  take/1,
  take/2,
  drain/1,
  pause/1,
  pipe/1,
  pipe/2,
  filter/2,
  map/2,
  reduce/2,
  is_empty/1,
  get_stream/1
]).

%% gen_fsm callbacks
-export([
  init/1,
  open/2,
  open/3,
  paused/2,
  paused/3,
  stopped/2,
  stopped/3,
  closed/2,
  closed/3,
  handle_event/3,
  handle_sync_event/4,
  handle_info/3,
  terminate/3,
  code_change/4
]).

-define(SERVER, ?MODULE).

%% States
-define(OPEN, open).
-define(PAUSED, paused).
-define(STOPPED, stopped).
-define(CLOSED, closed).

%%%===================================================================
%%% Interface functions.
%%%===================================================================

%%%===================================================================
%%% API
%%%===================================================================
-spec(start(any()) -> {ok, Pid} | {error, {already_started, Pid}} | {error, any()}).
start(Name) ->
  gen_fsm:start(?MODULE, [Name], []).

-spec(start_link(any(), any(), any(), any()) -> {ok, pid()} | ignore | {error, Reason :: term()}).
start_link(Name, Mod, Args, Options) ->
  gen_fsm:start_link(Name, Mod, Args, Options).

-spec(start_link() -> {ok, pid()} | ignore | {error, Reason :: term()}).
start_link() ->
  gen_fsm:start_link({local, ?SERVER}, ?MODULE, [], []).

put(StreamPID, Resource) -> gen_fsm:send_event(StreamPID, {put, Resource}).

take(StreamPID) -> gen_fsm:sync_send_event(StreamPID, take).

take(StreamPID, Number) -> gen_fsm:sync_send_event(StreamPID, {take, Number}).

drain(StreamPID) -> gen_fsm:send_all_state_event(StreamPID, drain).

pause(StreamPID) -> gen_fsm:send_all_state_event(StreamPID, pause).

filter(StreamPID, Fn) -> gen_fsm:send_all_state_event(StreamPID, {filter, Fn}).

map(StreamPID, Fn) -> gen_fsm:send_all_state_event(StreamPID, {map, Fn}).

reduce(StreamPID, Fn) -> gen_fsm:send_all_state_event(StreamPID, {reduce, Fn}).

is_empty(StreamPID) -> gen_fsm:sync_send_all_state_event(StreamPID, is_empty).

get_stream(StreamPID) -> gen_fsm:sync_send_all_state_event(StreamPID, get_stream).

-spec(pipe(any()) -> {ok, pid()}).
pipe(Mod) -> pipe(Mod, []).

-spec(pipe(any(), any()) -> {ok, pid()}).
pipe(Mod, Args) -> {ok, {?MODULE, {Mod, Args}}}.

%%%===================================================================
%%% gen_fsm callbacks
%%%===================================================================

-spec(init(Args :: term()) ->
  {ok, StateName :: atom(), StateData :: #stream{}} |
  {ok, StateName :: atom(), StateData :: #stream{}, timeout() | hibernate} |
  {stop, Reason :: term()} | ignore).
init(_Args) -> {ok, ?OPEN, stream:new()}.

%% ==========================================
%% OPEN STATE
%% ==========================================

open({put, _Resource}, #stream{is_paused = true} = Stream) -> {next_state, ?PAUSED, Stream};
open({put, _Resource}, #stream{is_stoped = true} = Stream) -> {next_state, ?STOPPED, Stream};
open({put, _Resource}, #stream{is_closed = true} = Stream) -> {next_state, ?CLOSED, Stream};

open({put, Resource}, #stream{} = Stream) when is_list(Resource) ->
  {ok, NewStream} = stream:put_from_list(Stream, Resource),
  {next_state, ?OPEN, NewStream};

open({put, Fn}, #stream{} = Stream) when is_function(Fn) ->
  {ok, NewStream} = stream:put_while(Stream, Fn),
  {next_state, ?OPEN, NewStream};

open({put, Resource}, #stream{} = Stream) ->
  {ok, NewStream} = stream:put(Stream, Resource),
  {next_state, ?OPEN, NewStream};

open(_Event, #stream{} = State) -> {next_state, ?OPEN, State}.

open(_Event, _From, #stream{is_closed = true} = Stream) -> {reply, {error, closed}, ?CLOSED, Stream};

open(take, _From, #stream{is_closed = false} = Stream) ->
  {NewStream, Resource} = stream:take(Stream),
  {reply, {ok, Resource}, ?OPEN, NewStream};

open({take, Number}, _From, #stream{is_closed = false} = Stream) ->
  {NewStream, ResourceList} = stream:take(Stream, Number),
  {reply, {ok, ResourceList}, ?OPEN, NewStream};

open(_Event, _From, State) -> {reply, {error, bad_call}, ?OPEN, State}.

%% ==========================================
%% PAUSED STATE
%% ==========================================

paused({put, _Resource}, Stream) -> {next_state, ?PAUSED, Stream};

paused(_Event, State) -> {next_state, ?PAUSED, State}.

paused(take, _From, #stream{is_closed = false} = Stream) ->
  {NewStream, Resource} = stream:take(Stream),
  {reply, {ok, Resource}, ?PAUSED, NewStream};

paused({take, Number}, _From, #stream{is_closed = false} = Stream) ->
  {NewStream, ResourceList} = stream:take(Stream, Number),
  {reply, {ok, ResourceList}, ?OPEN, NewStream};

paused(_Event, _From, State) -> {reply, {error, bad_call}, ?PAUSED, State}.

%% ==========================================
%% STOPPED STATE
%% ==========================================

stopped(_Event, #stream{} = Stream) -> {next_state, ?CLOSED, Stream#stream{is_stoped = true}}.

stopped(_Event, _From, #stream{} = Stream) -> {next_state, ?CLOSED, Stream#stream{is_stoped = true}}.

%% ==========================================
%% CLOSED STATE
%% ==========================================

closed(_Event, #stream{} = Stream) -> {next_state, ?CLOSED, Stream#stream{is_closed = true}}.

closed(_Event, _From, #stream{} = Stream) -> {next_state, ?CLOSED, Stream#stream{is_closed = true}}.

%% ==========================================
%% PIPE CALL
%% ==========================================

%% TODO
handle_event({pipe, _StreamPID}, StateName, #stream{} = Stream) ->
  {next_state, StateName, Stream};

%% ==========================================
%% DRAIN CALL
%% ==========================================

handle_event(drain, _StateName, #stream{
  is_closed = false,
  is_stoped = false
} = Stream) ->
  {next_state, ?OPEN, Stream#stream{is_paused = false}};

%% ==========================================
%% PAUSE CALL
%% ==========================================

handle_event(pause, _StateName, #stream{
  is_closed = false,
  is_stoped = false
} = Stream) ->
  {next_state, ?OPEN, Stream#stream{is_paused = true}};

%% ==========================================
%% FILTER CALL
%% ==========================================

handle_event({filter, Fn}, _StateName, #stream{
  is_closed = false,
  is_stoped = false
} = Stream) -> {next_state, ?OPEN, stream:filter(Stream, Fn)};

%% ==========================================
%% MAP CALL
%% ==========================================

handle_event({map, Fn}, _StateName, #stream{
  is_closed = false,
  is_stoped = false
} = Stream) -> {next_state, ?OPEN, stream:map(Stream, Fn)};

%% ==========================================
%% REDUCE CALL
%% ==========================================

handle_event({reduce, Fn}, _StateName, #stream{
  is_closed = false,
  is_stoped = false
} = Stream) -> {next_state, ?OPEN, stream:reduce(Stream, Fn)};

%% ==========================================
%% FALLBACK CALL
%% ==========================================

handle_event(_Event, StateName, State) -> {next_state, StateName, State}.

%% ==========================================
%% ZIP CALL
%% ==========================================

%% TODO

%% ==========================================
%% IS_EMPTY CALL
%% ==========================================

handle_sync_event(is_empty, _From, StateName, #stream{} = Stream) ->
  {reply, stream:is_empty(Stream), StateName, Stream};

%% ==========================================
%% GET_STREAM CALL
%% ==========================================

handle_sync_event(get_stream, _From, StateName, #stream{} = Stream) -> {reply, Stream, StateName, Stream};

%% ==========================================
%% FALLBACK CALL
%% ==========================================

handle_sync_event(_Event, _From, StateName, State) ->
  {reply, {error, bad_call}, StateName, State}.

handle_info(_Info, StateName, State) -> {next_state, StateName, State}.

terminate(_Reason, _StateName, _State) -> ok.

code_change(_OldVsn, StateName, State, _Extra) -> {ok, StateName, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
