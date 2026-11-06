-module(test).
-export([test/0, test/1, test/2]).

% test() ->
test() ->
    test_var = 1234,
    %% test_var = 5678,
    io:format("~p~n", [test_var]).

test(Foo) ->
    ok.

test(Foo, Bar) ->
    ok.
