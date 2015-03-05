# erlang_streams

[![Build Status](https://travis-ci.org/epappas/erl_streams.svg)](https://travis-ci.org/epappas/erl_streams)

A Stream wrapper library

# install

include it as a rebar dependency:

    {erl_streams, "*", {git, "git://github.com/epappas/erl_streams.git", {branch, "master"}}}

# Idea

## As process wrapper

### gen_stream

A generic stream generator, a smart queue with states and able to pause or drop on backpressure.

Example:

    %% Initiate Simple Stream
    {ok, StreamPID} = gen_stream:start(test),

    %% Simple put & take
    ok = gen_stream:put(StreamPID, 1),
    {ok, 1} = gen_stream:take(StreamPID),
    
    %% Pause state
    ok = gen_stream:pause(StreamPID),
    {error, pause} = gen_stream:put(StreamPID, test),
    ok = gen_stream:drain(StreamPID),
    ok = gen_stream:put(StreamPID, 1),
    {ok, 1} = gen_stream:take_and_pause(StreamPID),
    true = gen_stream:is_paused(StreamPID),
    
    %% Set a Max size, to manage back pressure
    {ok, StreamPID} = gen_stream:start(test, 1),
    ok = gen_stream:put(StreamPID, test),
    {error, pause} = gen_stream:put(StreamPID, test),
    {ok, test} = gen_stream:take(StreamPID),
    ok = gen_stream:put(StreamPID, test),
    

#### Methods

##### gen_stream:start/0,

Creates an anonymous stream

    gen_stream:start() -> {ok, Pid} | {error, {already_started, Pid}} | {error, any()}
    
##### gen_stream:start/1,

Creates a Named stream with default settings

    gen_stream:start(any()) -> {ok, Pid} | {error, {already_started, Pid}} | {error, any()}
    
##### gen_stream:start/2,

Creates a Named stream with Max buffer or wraps a stream that implements the `gen_stream` behaviour

    gen_stream:start(any(), number() | atom()) -> {ok, Pid} | {error, {already_started, Pid}} | {error, any()}
    
    {ok, Pid} = gen_stream:start(test, 10),
    {ok, Pid} = gen_stream:start(test, simple_stream)
    
##### gen_stream:start/3,

    gen_stream:start(any(), number() | atom(), list() | number()) -> {ok, Pid} | {error, {already_started, Pid}} | {error, any()}

    {ok, Pid} = gen_stream:start(test, simple_stream, 10),
    {ok, Pid} = gen_stream:start(test, simple_stream, InitArgs)

##### gen_stream:start/4,

    gen_stream:start(any(), number(), atom(), list()) -> {ok, Pid} | {error, {already_started, Pid}} | {error, any()}

    {ok, Pid} = gen_stream:start(test, 10, simple_stream, InitArgs)
    
##### gen_stream:put/2,

    gen_stream:put(pid(), any()) -> ok | {error, pause}
    
##### gen_stream:put_from_list/2,

    gen_stream:put_from_list(pid(), list()) -> ok | {error, pause}
    
##### gen_stream:put_while/2,

    gen_stream:put_while(pid(), fun()) -> ok | {error, pause}

where fun()

    fun (_StreamPid) -> 
        Resource
    end
    
##### gen_stream:take/1,

    gen_stream:take(pid()) -> {ok, any()}
    
Take gives `undefined` when stream is empty
    
##### gen_stream:take/2,

Take a number of resources

    gen_stream:take(pid(), number()) -> {ok, any()}
    
##### gen_stream:take_and_pause/2,

The stream will be paused after this call

    gen_stream:take_and_pause(pid()) -> {ok, any()}
    
##### gen_stream:drain/1,

Unpause the stream, if the stream is blocked due to back pressure, then drain is not affecting
    
    gen_stream:drain(pid()) -> ok
    
##### gen_stream:resume/1,

Stream will no drop anymore
    
    gen_stream:resume(pid()) -> ok    

##### gen_stream:drop/1,

Streams is in a drop state, each inputted resource will be ignored, and the response will be `ok`

    gen_stream:drop(pid()) -> ok
    
##### gen_stream:drop_while/2,

    gen_stream:drop_while(pid(), fun()) -> ok

Where `fun/2`

    Dropping_Fn(StreamPid, Resource) -> boolean()
    
##### gen_stream:pause/1,

    gen_stream:pause(pid()) -> ok
    
##### gen_stream:filter/2,

    gen_stream:filter(pid(), fun()) -> ok
    
Where `fun/2`

    FilterFn(Resource, Buffer) -> boolean()
    
##### gen_stream:map/2,

    gen_stream:map(pid(), fun()) -> ok
    
Where `fun/2`

    MapFn(Resource, Buffer) -> Resource :: any()
    
##### gen_stream:reduce/2,

    gen_stream:reduce(pid(), fun()) -> ok
    
Where `fun/2`

    ReduceFn(Acc, Resource, Buffer) -> NewAcc :: any()
    
##### gen_stream:can_accept/1,

    gen_stream:can_accept(pid()) -> boolean()
    
##### gen_stream:is_empty/1,

    gen_stream:is_empty(pid()) -> boolean()
    
##### gen_stream:is_paused/1,

    gen_stream:is_paused(pid()) -> boolean()
    
##### gen_stream:is_closed/1,

    gen_stream:is_closed(pid()) -> boolean()
    
##### gen_stream:is_stopped/1,

    gen_stream:is_stopped(pid()) -> boolean()
    
##### gen_stream:is_open/1,

    gen_stream:is_open(pid()) -> boolean()


#### As a data structure

###### stream

A data structure with cases to handle backpressure, paused and closed states
