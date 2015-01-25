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

%% API
-export([
  start/1,
  start_link/0,
  start_link/4,
  pipe/1,
  pipe/2
]).

%% gen_fsm callbacks
-export([
  init/1,
  state_name/2,
  state_name/3,
  handle_event/3,
  handle_sync_event/4,
  handle_info/3,
  terminate/3,
  code_change/4
]).

-define(SERVER, ?MODULE).

-record(state, {
  is_paused = false,
  is_stoped = false,
  is_reading = false,
  is_writing = false,
  has_started = false,
  pipes = [],
  buffer = []
}).

%%%===================================================================
%%% Interface functions.
%%%===================================================================

-callback init(Args :: term()) ->
  {ok, StateName :: atom(), StateData :: term()} |
  {ok, StateName :: atom(), StateData :: term(), timeout() | hibernate} |
  {stop, Reason :: term()} | ignore.
-callback handle(
    Event :: term(),
    StateName :: atom(),
    StateData :: term()
) ->
  {next, NextStateName :: atom(), NewStateData :: term()} |
  {next, NextStateName :: atom(), NewStateData :: term(), timeout()} |
  {stop, NewStateData :: term()} |
  {stop, Reason :: term(), NewStateData :: term()} |
  {error, Reason :: term(), NewStateData :: term()}.
-callback close(Reason :: normal | shutdown | {shutdown, term()} | term(),
    StateName :: atom(),
    StateData :: term()
) -> term().
-callback code_change(
    OldVsn :: term() |
    {down, term()}, StateName :: atom(),
    StateData :: term(), Extra :: term()
) ->
  {ok, NextStateName :: atom(), NewStateData :: term()}.

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

-spec(pipe(any()) -> {ok, pid()}).
pipe(Mod) -> pipe(Mod, []).

-spec(pipe(any(), any()) -> {ok, pid()}).
pipe(Mod, Args) -> {ok, {?MODULE, {Mod, Args}}}.

%%%===================================================================
%%% gen_fsm callbacks
%%%===================================================================

-spec(init(Args :: term()) ->
  {ok, StateName :: atom(), StateData :: #state{}} |
  {ok, StateName :: atom(), StateData :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term()} | ignore).
init([]) ->
  {ok, state_name, #state{}}.

-spec(state_name(Event :: term(), State :: #state{}) ->
  {next_state, NextStateName :: atom(), NextState :: #state{}} |
  {next_state, NextStateName :: atom(), NextState :: #state{},
    timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #state{}}).
state_name(_Event, State) ->
  {next_state, state_name, State}.

-spec(state_name(Event :: term(), From :: {pid(), term()},
    State :: #state{}) ->
  {next_state, NextStateName :: atom(), NextState :: #state{}} |
  {next_state, NextStateName :: atom(), NextState :: #state{},
    timeout() | hibernate} |
  {reply, Reply, NextStateName :: atom(), NextState :: #state{}} |
  {reply, Reply, NextStateName :: atom(), NextState :: #state{},
    timeout() | hibernate} |
  {stop, Reason :: normal | term(), NewState :: #state{}} |
  {stop, Reason :: normal | term(), Reply :: term(),
    NewState :: #state{}}).
state_name(_Event, _From, State) ->
  Reply = ok,
  {reply, Reply, state_name, State}.

-spec(handle_event(Event :: term(), StateName :: atom(),
    StateData :: #state{}) ->
  {next_state, NextStateName :: atom(), NewStateData :: #state{}} |
  {next_state, NextStateName :: atom(), NewStateData :: #state{},
    timeout() | hibernate} |
  {stop, Reason :: term(), NewStateData :: #state{}}).
handle_event(_Event, StateName, State) ->
  {next_state, StateName, State}.

-spec(handle_sync_event(Event :: term(), From :: {pid(), Tag :: term()},
    StateName :: atom(), StateData :: term()) ->
  {reply, Reply :: term(), NextStateName :: atom(), NewStateData :: term()} |
  {reply, Reply :: term(), NextStateName :: atom(), NewStateData :: term(),
    timeout() | hibernate} |
  {next_state, NextStateName :: atom(), NewStateData :: term()} |
  {next_state, NextStateName :: atom(), NewStateData :: term(),
    timeout() | hibernate} |
  {stop, Reason :: term(), Reply :: term(), NewStateData :: term()} |
  {stop, Reason :: term(), NewStateData :: term()}).
handle_sync_event(_Event, _From, StateName, State) ->
  Reply = ok,
  {reply, Reply, StateName, State}.

-spec(handle_info(Info :: term(), StateName :: atom(),
    StateData :: term()) ->
  {next_state, NextStateName :: atom(), NewStateData :: term()} |
  {next_state, NextStateName :: atom(), NewStateData :: term(),
    timeout() | hibernate} |
  {stop, Reason :: normal | term(), NewStateData :: term()}).
handle_info(_Info, StateName, State) ->
  {next_state, StateName, State}.

-spec(terminate(Reason :: normal | shutdown | {shutdown, term()}
| term(), StateName :: atom(), StateData :: term()) -> term()).
terminate(_Reason, _StateName, _State) ->
  ok.

-spec(code_change(OldVsn :: term() | {down, term()}, StateName :: atom(),
    StateData :: #state{}, Extra :: term()) ->
  {ok, NextStateName :: atom(), NewStateData :: #state{}}).
code_change(_OldVsn, StateName, State, _Extra) ->
  {ok, StateName, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
