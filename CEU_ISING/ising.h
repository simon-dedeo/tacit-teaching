#include <stdio.h> 
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <time.h>
#include <unistd.h> // we use this to get process ID and help randomness

#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>
#include <gsl/gsl_math.h>
#include <gsl/gsl_eigen.h>
#include <gsl/gsl_complex_math.h>

#define BIG 1e6
#define BIGI 1e-6
#define EPSILON 1e-16

typedef struct {
	int n;	// number of nodes
    int *count; // number of nodes connected to each node
    int **links; // links
    double **links_val; // link weight
    int *val; // node value
    double *exp_calc; // exp calc
    int **modules; // membership of each module
    int *n_members; // number of members in each module
    int n_module; // total number of modules
    int n_axioms; // total number of axioms
    int *axioms;
    double axiom_prob;
    int n_theorems; // total number of axioms
    int *theorems;
    int max_deg;
    double *pagerank;
    double *fields;
    double beta;
} graph;

gsl_rng *r;

graph *init_graph();
void delete_graph(graph *g);
void read_graph(char *filename, graph *g);
void read_weights(char *filename, graph *g);
void read_teacher(char *filename, graph *g);
double total_energy_spin(graph *g);
void read_fields(char *filename, graph *g);
void print_graph(graph *g);
void clear_graph(graph *g);
void update_graph(graph *g);

double avg_val(graph *g);
double total_energy(graph *g);

void set_axiom_prob(graph *g, double beta);
double non_axiom_truth(graph *g);
double axiom_truth(graph *g);

void read_modules(char *filename, char *filename_axioms, char *filename_theorems, char *filename_pagerank, graph *g);

double avg_theorems(graph *g);
double avg_pagerank(graph *g);

double abs_avg_modules(graph *g);
double avg_modules(graph *g);
double abs_avg(graph *g);

double mean(double *list, int n);
double variance(double *list, int n);

void paramagnetic_modules(graph *g);
void fix_module_false(graph *g, int module_named);
void fix_random_module_false(graph *g, int module_named);
void fix_all_true(graph *g);