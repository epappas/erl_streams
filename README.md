# erlang_streams

[![Build Status](https://travis-ci.org/epappas/erl_streams.svg)](https://travis-ci.org/epappas/erl_streams)

A Stream wrapper library

# install

include it as a rebar dependency:

    {erl_streams, "*", {git, "git://github.com/epappas/erl_streams.git", {branch, "master"}}}

# Idea

#### As process wrapper

###### gen_stream

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
    

#### As a data structure

###### stream

A data structure with cases to handle backpressure, paused and closed states
