ERL          ?= erl
ERLC		 ?= erlc
APP          := erl_streams
REBAR        ?= ./rebar

all: deps compile test doc

deps:
	@$(REBAR) -C rebar.config get-deps

compile:
	@$(REBAR) -C rebar.config compile

test:
	@$(ERLC) -o tests/ tests/*.erl
	prove -v tests/*.t

doc:
	$(REBAR) -C rebar.config doc skip_deps=true

cover: all
	COVER=1 prove tests/*.t
	@$(ERL) -detached -noshell -eval 'etap_report:create()' -s init stop

clean:
	@$(REBAR) clean
	@rm -f bin/*.beam
	@rm -f tests/*.beam
	@rm -f doc/*.html doc/*.css doc/edoc-info doc/*.png
