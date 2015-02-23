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
  start/0,
  start/1,
  start/2,
  start/3,
%%   TODO start_link/0,
%%   TODO start_link/4,
  put/2,
  put_from_list/2,
  put_while/2,
  take/1,
  take/2,
  take_and_pause/1,
%%   TODO drop/1,
%%   TODO drop_while/1,
%%   TODO delay/1,
%%   TODO delay_while/1,
  drain/1,
  pause/1,
  pipe/1,
  pipe/2,
  filter/2,
  map/2,
  reduce/2,
  can_accept/1,
  is_empty/1,
  is_paused/1,
  is_closed/1,
  is_stopped/1,
  is_open/1,
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
-spec(start() -> {ok, Pid} | {error, {already_started, Pid}} | {error, any()}).
start() ->
  gen_fsm:start(?MODULE, [], []).

-spec(start(any()) -> {ok, Pid} | {error, {already_started, Pid}} | {error, any()}).
start(Name) ->
  gen_fsm:start(?MODULE, [{name, Name}], []).

start(Name, Max) when is_number(Max) ->
  gen_fsm:start(?MODULE, [{name, Name}, {max, Max}], []);

start(Name, Mod) when is_atom(Mod) ->
  gen_fsm:start(?MODULE, [{name, Name}, {mod, Mod}], []).

start(Name, Mod, Max) ->
  gen_fsm:start(?MODULE, [{name, Name}, {mod, Mod}, {max, Max}], []).

%% -spec(start_link(any(), any(), any(), any()) -> {ok, pid()} | ignore | {error, Reason :: term()}).
%% start_link(Name, Mod, Args, Options) ->
%%   gen_fsm:start_link(Name, Mod, Args, Options).
%%
%% -spec(start_link() -> {ok, pid()} | ignore | {error, Reason :: term()}).
%% start_link() ->
%%   gen_fsm:start_link({local, ?SERVER}, ?MODULE, [], []).

put(StreamPID, Resource) ->
  case gen_stream:can_accept(StreamPID) of
    true -> gen_fsm:send_event(StreamPID, {put, Resource});
    false ->
      case gen_stream:is_paused(StreamPID) of
        true -> {error, pause};
        false ->
          case gen_stream:is_stopped(StreamPID) of
            true -> {error, stopped};
            false -> {error, closed}
          end
      end
  end.

-spec(put_from_list(StreamPID :: pid(), ResourceList :: list()) ->
  {ok, #stream{}} | {paused, #stream{} | {stopped, #stream{}} | {closed, #stream{}}}).
put_from_list(_StreamPID, ResourceList) when ResourceList =:= [] -> ok;
put_from_list(StreamPID, ResourceList) ->
  [H | T] = ResourceList,
  case gen_stream:put(StreamPID, H) of
    ok -> stream:put_from_list(StreamPID, T);
    OtherState -> OtherState %% closed, isPaused, or anything else
  end.

-spec(put_while(StreamPID :: pid(), Fn :: fun()) ->
  {ok, #stream{}} | {paused, #stream{} | {stopped, #stream{}} | {closed, #stream{}}}).
put_while(StreamPID, Fn) when is_function(Fn) ->
  case Fn(StreamPID) of
    undefined -> ok;
    Resource -> gen_stream:put(StreamPID, Resource)
  end.

take(StreamPID) -> gen_fsm:sync_send_event(StreamPID, take).

take(StreamPID, Number) -> gen_fsm:sync_send_event(StreamPID, {take, Number}).

take_and_pause(StreamPID) -> gen_fsm:sync_send_event(StreamPID, take_and_pause).

drain(StreamPID) -> gen_fsm:send_all_state_event(StreamPID, drain).

pause(StreamPID) -> gen_fsm:send_all_state_event(StreamPID, pause).

filter(StreamPID, Fn) -> gen_fsm:send_all_state_event(StreamPID, {filter, Fn}).

map(StreamPID, Fn) -> gen_fsm:send_all_state_event(StreamPID, {map, Fn}).

reduce(StreamPID, Fn) -> gen_fsm:send_all_state_event(StreamPID, {reduce, Fn}).

can_accept(StreamPID) -> gen_fsm:sync_send_all_state_event(StreamPID, can_accept).

is_empty(StreamPID) -> gen_fsm:sync_send_all_state_event(StreamPID, is_empty).

is_paused(StreamPID) -> gen_fsm:sync_send_all_state_event(StreamPID, is_paused).

is_closed(StreamPID) -> gen_fsm:sync_send_all_state_event(StreamPID, is_closed).

is_stopped(StreamPID) -> gen_fsm:sync_send_all_state_event(StreamPID, is_stopped).

is_open(StreamPID) -> gen_fsm:sync_send_all_state_event(StreamPID, is_open).

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
init([]) -> {ok, ?OPEN, stream:new()};

init(ArgsList) when is_list(ArgsList) ->
  Name = proplists:get_value(name, ArgsList, new_stream),
  Max = proplists:get_value(max, ArgsList, 134217728),
  Mod = proplists:get_value(mod, ArgsList, undefined),

  Stream = stream:new(Name, Max),

  {ok, ?OPEN, Stream#stream{mod = Mod}}.

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

open({put, Resource}, #stream{mod = undefined} = Stream) ->
  case stream:put(Stream, Resource) of
    {ok, NewStream} ->
      {next_state, ?OPEN, NewStream};
    {pause, NewStream} ->
      {next_state, ?PAUSED, NewStream};
    {stopped, NewStream} ->
      {next_state, ?STOPPED, NewStream};
    {closed, NewStream} ->
      {next_state, ?CLOSED, NewStream}
  end;

open({put, Resource}, #stream{mod = Mod} = Stream) ->
  case Mod:on_data(Stream, Resource) of
    {ignore, MaybeNewStream} -> {next_state, ?OPEN, MaybeNewStream};
    {ok, MaybeNewStream} ->
      case stream:put(Stream, Resource) of
        {ok, NewStream} ->
          {next_state, ?OPEN, NewStream};
        {pause, NewStream} ->
          {next_state, ?PAUSED, NewStream};
        {stopped, NewStream} ->
          {next_state, ?STOPPED, NewStream};
        {closed, NewStream} ->
          {next_state, ?CLOSED, NewStream}
      end
  end;

open(_Event, #stream{} = State) -> {next_state, ?OPEN, State}.

%% ===== Syncronous =====

open(_Event, _From, #stream{is_closed = true} = Stream) -> {reply, {error, closed}, ?CLOSED, Stream};

open(_Event, _From, #stream{is_stoped = true} = Stream) -> {reply, {error, stopped}, ?STOPPED, Stream};

open(take, _From, #stream{is_closed = false, mod = undefined} = Stream) ->
  {NewStream, Resource} = stream:take(Stream),
  {reply, {ok, Resource}, ?OPEN, NewStream};

open(take, _From, #stream{is_closed = false, mod = Mod} = Stream) ->
  {NewStream, Resource} = stream:take(Stream),
  {MaybeNewStream, RSrc} = Mod:on_offer(NewStream, Resource),
  {reply, {ok, RSrc}, ?OPEN, MaybeNewStream};

open(take_and_pause, _From, #stream{is_closed = false, mod = undefined} = Stream) ->
  {NewStream, Resource} = stream:take_and_pause(Stream),
  {reply, {ok, Resource}, ?PAUSED, NewStream};

open(take_and_pause, _From, #stream{is_closed = false, mod = Mod} = Stream) ->
  {NewStream, Resource} = stream:take_and_pause(Stream),
  {MaybeNewStream, RSrc} = Mod:on_offer(NewStream, Resource),
  {reply, {ok, RSrc}, ?PAUSED, MaybeNewStream};

open({take, Number}, _From, #stream{is_closed = false, mod = undefined} = Stream) ->
  {NewStream, ResourceList} = stream:take(Stream, Number),
  {reply, {ok, ResourceList}, ?OPEN, NewStream};

open({take, Number}, _From, #stream{is_closed = false, mod = Mod} = Stream) ->
  {NewStream, ResourceList} = stream:take(Stream, Number),
  {MaybeNewStream, RSrcList} = Mod:on_offer(NewStream, ResourceList),
  {reply, {ok, RSrcList}, ?OPEN, MaybeNewStream};

open(_Event, _From, State) -> {reply, {error, bad_call}, ?OPEN, State}.

%% ==========================================
%% PAUSED STATE
%% ==========================================

paused({put, _Resource}, Stream) -> {next_state, ?PAUSED, Stream};

paused(_Event, State) -> {next_state, ?PAUSED, State}.

%% ===== Syncronous =====

paused(_Event, _From, #stream{is_closed = true} = Stream) -> {reply, {error, closed}, ?CLOSED, Stream};

paused(_Event, _From, #stream{is_stoped = true} = Stream) -> {reply, {error, stopped}, ?STOPPED, Stream};

paused(take, _From, #stream{is_closed = false} = Stream) ->
  {NewStream, Resource} = stream:take(Stream),
  {reply, {ok, Resource}, ?PAUSED, NewStream};

paused(take_and_pause, _From, #stream{is_closed = false} = Stream) ->
  {NewStream, Resource} = stream:take_and_pause(Stream),
  {reply, {ok, Resource}, ?PAUSED, NewStream};

paused({take, Number}, _From, #stream{is_closed = false} = Stream) ->
  {NewStream, ResourceList} = stream:take(Stream, Number),
  {reply, {ok, ResourceList}, ?PAUSED, NewStream};

paused(_Event, _From, State) -> {reply, {error, bad_call}, ?PAUSED, State}.

%% ==========================================
%% STOPPED STATE
%% ==========================================

stopped(_Event, #stream{} = Stream) -> {next_state, ?STOPPED, Stream#stream{is_stoped = true}}.

stopped(_Event, _From, #stream{} = Stream) -> {next_state, ?STOPPED, Stream#stream{is_stoped = true}}.

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
  {next_state, ?PAUSED, Stream#stream{is_paused = true}};

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
%% IS_PAUSED CALL
%% ==========================================

handle_sync_event(can_accept, _From, ?OPEN, #stream{
  is_paused = false,
  is_closed = false,
  is_stoped = false,
  buffer = Buffer,
  max_buffer = MAX
} = Stream) when length(Buffer) < MAX ->
  {reply, true, ?OPEN, Stream};

handle_sync_event(can_accept, _From, StateName, #stream{} = Stream) ->
  {reply, false, StateName, Stream};

%% ==========================================
%% IS_PAUSED CALL
%% ==========================================

handle_sync_event(is_paused, _From, ?PAUSED, #stream{} = Stream) ->
  {reply, true, ?PAUSED, Stream};

handle_sync_event(is_paused, _From, _StateName, #stream{
  is_paused = false,
  buffer = Buffer,
  max_buffer = MAX
} = Stream) when length(Buffer) >= MAX ->
  {reply, true, ?PAUSED, Stream};

handle_sync_event(is_paused, _From, StateName, #stream{} = Stream) ->
  {reply, false, StateName, Stream};

%% ==========================================
%% IS_CLOSED CALL
%% ==========================================

handle_sync_event(is_closed, _From, ?CLOSED, #stream{} = Stream) ->
  {reply, true, ?CLOSED, Stream};

handle_sync_event(is_closed, _From, StateName, #stream{} = Stream) ->
  {reply, false, StateName, Stream};

%% ==========================================
%% IS_STOPPED CALL
%% ==========================================

handle_sync_event(is_stopped, _From, ?STOPPED, #stream{} = Stream) ->
  {reply, true, ?STOPPED, Stream};

handle_sync_event(is_stopped, _From, StateName, #stream{} = Stream) ->
  {reply, false, StateName, Stream};

%% ==========================================
%% IS_OPEN CALL
%% ==========================================

handle_sync_event(is_open, _From, ?OPEN, #stream{} = Stream) ->
  {reply, true, ?OPEN, Stream};

handle_sync_event(is_open, _From, StateName, #stream{} = Stream) ->
  {reply, false, StateName, Stream};

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
