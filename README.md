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

#### As a data structure

###### stream

A data structure with cases to handle backpressure, paused and closed states
