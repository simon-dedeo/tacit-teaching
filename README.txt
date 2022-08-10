This Repository contains two collections of code:

1. CEU_ISING: C Code that implements a version of the Metropolis-Hastings algorithm on spin glass networks, that enables you to

(A) simulate the statistics of the facets for a learner at different values of beta -- this is useful to explore the space of practices.

(B) simulate the interaction of a learner (at dfferent values of beta) and a teacher (at different values of tau).

This code is named CEU_ISING, after the Central European University where this work was begun. The calculations necessary to approximate the statisics of these systems are quite intense, and the code is thus is highly optimized ANSI C code that reads in files that describe the network and (potentially) the teacher interventions, and then runs from the command line.

2. RUBY_TACIT: Ruby code to

(A) construct networks, convert them into the specialized format required by CEU_ISING, and run teaching simulations.

(B) find (locally) optimal solutions for teaching interventions, using a simple greedy algorithm.

With these two piece of code in hand, it is then possible to reproduce the results reported in our paper. In some cases, the computational demands are quite intense; for example, finding the optimal teaching intervention can take up to two minutes on legacy hardware, so simulating evolution for a thousand generations can take up to a day of computer time. There are ways to speed this up (in particular, we found it useful to take advantage of parallel processing when computing the teaching interventions, and to cache results); for simplicitly, however, we do not present the optimized versions -- please contact Simon (sdedeo@andrew.cmu.edu) if you are interested in brainstorming how to get more advanced experiments running on your machine.

******

CEU_ISING

To compile the C code, cd to the CEU_ISING directory, type "make clean", then type "make". This is tested and works on Mac OS X 10.12, on the new Mac M1s, and on Gentoo Linux.

CEU_ISING has two modes: (1) simulating the distribution over facets for a particular network in the absence of interventions; and (2) simuating the distribution of facets for a particular network in the presence of interventions.

(1) simulating the distribution over facets for a particular network in the absence of interventions, use the -m option and pass a filename with the network. It sets beta to 100 and iterates quickly (quenching) so it can find anything that's locally stable. Every time you run it, you'll get a different output; the equilibria with wider basins of attraction will appear more often, a nice indicator of teachability.

./ising -m network_connections.dat

The network connection file has a special form. On the first line is the number of nodes. 

Then each subsequent line is associated with the nodes in order. The first number is the number of links it has. Then there are pairs of numbers, the first in the pair is the node linked to (zero numbered), and the second in the pair is the weight.

For example, if you had a network of three nodes, with node 0 linking to 1 with weight 0.3, and node 2 linking to node 1 with weight -0.4, the file would have four lines and look like this:

3
1 1 0.3
2 0 0.3 2 -0.4
1 1 -0.4

i.e, in words: three nodes. Node zero has one link, to node one, weight 0.3. Node one has two links; one to node zero with weight 0.3, one to node two with weight -0.4. Node two has one link, to node one with weight -0.4

The code will spit out a list of node values in order, e.g., "0 1 0"

To find lots of equilibria, run the code, say, 1,000 or 10,000 times, and count to see how many times you get the same answers. This maps out the space of possible practices.

(2) simuating the distribution of facets for a particular network in the presence of interventions, use the -t option and pass two files and the beta value. 

./ising -t network_connections.dat network_interventions.dat [betavalue]

The first is the network connections, as above. The second is the list of interventions, as follows: first, the number of nodes in the network, then on a second line, the strength of each intervention. Set the value to zero if you *don't* want the teacher to engage there. For example, if you wanted to have one intervention, only on node one, in the negative (meaning, favoring zero) direction, with tau equal to ten, then you would have the file

3
0 -10 0

and you might pass it to CEU_ISING with the beta set to 2.0.

./ising -t network_connections.dat network_interventions.dat 2.0

******

RUBY_TACIT

Packages required (use gem install): parallel (so you can run quickly on multiple cores), levenshtein (to compute the Levenshtein distribution), distribution (helper functions, just a fast version of factorial), random_graph (so you can try Watts-Strogatz)

construct_networks.rb provides commented ruby code showing how to create a network, and then use CEU_ISING to learn about the different potential equilibria (cultural practices) that it can support.

simple_teacher.rb shows the details of the greedy algorithm used to find the optimal teaching interventions, and then shows how to use them to simulate the chained transmission process where a student learns from a teacher, ends up with his own new practice, and must teach it to the next generation.

heatmap.rb shows how to scan the space of beta and tau to look at how effective teaching is.

topology_tests.rb show how to try different topologies.

copy_leaps.rb shows how to simulate outcomes from teaching in detail, as well as the details of how to compute Hamming distance, how to compare it to the copy-model, and the use of the Levenshtein distance.

******

The Figures in the paper were produced by IDL (Interactive Data Language).
