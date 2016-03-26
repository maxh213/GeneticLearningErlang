-module(ga).
-compile(export_all).


%A mutation rate of 2 with a cap of 10 would mean a 20% mutation rate
-define(MUTATION_CAP, 10).
-define(MUTATION_RATE, 2).

%Crossover is done from the surviving population in tournament selection.
%Half the previous generation was wiped out and so they are replaced by children of the successful.

%It will take a fraction of the time if you give a population size of 400 or less.
%However a larger population will get the job done in loess generations and is easier to watch.
-define(POPULATION_SIZE, 4000).
-define(TARGET, "I'm learning!").

start() ->
	random:seed(now()),
	random:seed(now()),
	Pop = generatePop(),
	start(Pop, 0).

start(Pop, I) ->
	ParentPop = tournamentSelection(Pop),
	NewPop = breed(ParentPop),
	MNewPop = performMutations(NewPop),
	Best = getBest(MNewPop),
	io:format("Generation "),
	io:format("~p",[I]),
	io:format("~n"),
	io:format("Best attempt: " ++ [Best]++"~n"),
	case Best == ?TARGET of
		true ->
			Best;
		false ->
			start(MNewPop, I+1)
	end.
	
generatePop() ->
	generatePop(0, []).

generatePop(I, P) when I < ?POPULATION_SIZE ->
	generatePop(I+1, P ++ [rndString(string:len(?TARGET))]);
generatePop(_I, P) ->
	P. 

%generates a random string the length of N
rndString(N) ->
	lists:map(fun (_) -> random:uniform(90)+$\s+1 end, lists:seq(1,N)).
	
%C = chromosome
fitness(C) -> 
	fitness(C, ?TARGET, 0).

fitness(_, [], F) ->
	F;
fitness([], _, F) ->
	F;
%Basically, find the difference between the ascii values of the target and
%the chromosomes individual chars and add to the result. 
%Lower fitness is better, 0 is the best fitness
fitness([C|Cs], [T|Ts], F) ->
	fitness(Cs, Ts, F+abs(T - C)).
	
tournamentSelection(P) ->
	shuffle(P),
	{P1, P2} = lists:split(length(P) div 2, P),
	tournamentSelection(P1, P2, []).

%NP = new population
tournamentSelection([], _, NP) ->
	NP;
tournamentSelection([P1|P1s], [P2|P2s], NP)  ->
	case fitness(P1) =< fitness(P2) of
		true ->
			tournamentSelection(P1s, P2s, NP ++ [P1]);
		false ->
			tournamentSelection(P1s, P2s, NP ++ [P2])
	end.

%splits two words in two and merges them
%"hello" and "wasup" would make the children "wallo" and "hesup" for example
crossover(P1, P2) ->
	{P11, P12} = lists:split(length(P1) div 2, P1),
	{P21, P22} = lists:split(length(P2) div 2, P2),
	[P11 ++ P22] ++ [P21 ++ P12].

performMutations(P) ->
	performMutations(P, []).

%NP = New population
performMutations([], NP) ->
	NP;
performMutations([P|Ps], NP) ->
	case random:uniform(?MUTATION_CAP) =< ?MUTATION_RATE of
		true ->
			performMutations(Ps, NP ++ [mutate(P)]);
		false ->
			performMutations(Ps, NP ++ [P])
	end.
			

%This takes a random character in a string and changes it to another
%character 5 ascii characters away from it
mutate(P1) ->
	I = random:uniform(length(P1)),
	FHalf = lists:sublist(P1, I-1),
	MutPoint = lists:nth(I, P1),
	LHalf = lists:nthtail(I, P1),
	%randomly decide whether to go 5 ascii characters up or down
	case random:uniform(2) of 
		1 ->
			FHalf ++ [(MutPoint + random:uniform(5))] ++ LHalf;
		2 ->
			FHalf ++ [(MutPoint - random:uniform(5))] ++ LHalf	
	end.

getBest([P|Ps]) ->
	getBest(Ps, P).

%B = Best
getBest([], B) ->
	B;
getBest([P|Ps], B) ->
	case fitness(B) > fitness(P) of
		true ->
			getBest(Ps, P);
		false ->
			getBest(Ps, B)
	end.

breed(P) ->
	{P1, P2} = lists:split(length(P) div 2, P),
	breed(P1, P2, []).

breed([], _, NP) ->
	NP;
breed(_, [], NP) ->
	NP;
breed([P1|P1s], [P2|P2s], NP) ->
	breed(P1s, P2s, NP ++ [P1] ++ [P2] ++ crossover(P1,P2)).
		
%List randomiser taken from:
%https://erlangcentral.org/wiki/index.php?title=RandomShuffle
shuffle(List) ->
%% Determine the log n portion then randomize the list.
   randomize(round(math:log(length(List)) + 0.5), List).
 
randomize(1, List) ->
   randomize(List);
randomize(T, List) ->
   lists:foldl(fun(_E, Acc) ->
                  randomize(Acc)
               end, randomize(List), lists:seq(1, (T - 1))).
 
randomize(List) ->
   D = lists:map(fun(A) ->
                    {random:uniform(), A} end, List),
   {_, D1} = lists:unzip(lists:keysort(1, D)), D1.
