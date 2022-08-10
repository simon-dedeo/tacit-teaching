#include "ising.h"

graph *init_graph() {
    graph *g;
	
	g=(graph *)malloc(sizeof(graph));
	g->n=-1;
    g->count=NULL;
    g->links=NULL;
    g->val=NULL;
    g->links_val=NULL;
    
	return g;
}

void read_graph(char *filename, graph *g) {
    // first, number of nodes
    // then, for each node: (1) the number of links, (2) the links, in order
	int i, j, max_deg=-1;
	FILE *f_in;
	
	f_in=fopen(filename, "r");
	
	fscanf(f_in, "%i\n", &(g->n)); // first, number of nodes
    g->count=(int *)malloc((g->n)*sizeof(int));
    g->val=(int *)malloc((g->n)*sizeof(int));
    g->links=(int **)malloc((g->n)*sizeof(int *));
    for(i=0;i<g->n;i++) {
        fscanf(f_in, "%i ", &(g->count[i]));
        if (g->count[i] > max_deg) {
            max_deg=g->count[i];
        }
        g->links[i]=(int *)malloc(g->count[i]*sizeof(int));
        for(j=0;j<g->count[i];j++) {
            fscanf(f_in, "%i ", &(g->links[i][j]));
        }
    }
    g->exp_calc=(double *)malloc((max_deg+1)*sizeof(double));
    g->max_deg=max_deg+1;
	fclose(f_in);	
	
}

void read_weights(char *filename, graph *g) {
    // first, number of nodes
    // then, for each node: (1) the number of links, (2) the links, in order
	int i, j, max_deg=-1;
	FILE *f_in;
	
	f_in=fopen(filename, "r");
	
	fscanf(f_in, "%i\n", &(g->n)); // first, number of nodes
    g->count=(int *)malloc((g->n)*sizeof(int));
    g->val=(int *)malloc((g->n)*sizeof(int));
    g->links=(int **)malloc((g->n)*sizeof(int *));
    g->links_val=(double **)malloc((g->n)*sizeof(double *));
    for(i=0;i<g->n;i++) {
        fscanf(f_in, "%i ", &(g->count[i]));
        if (g->count[i] > max_deg) {
            max_deg=g->count[i];
        }
        g->links[i]=(int *)malloc(g->count[i]*sizeof(int));
        g->links_val[i]=(double *)malloc(g->count[i]*sizeof(double));
        for(j=0;j<g->count[i];j++) {
            fscanf(f_in, "%i ", &(g->links[i][j]));
            fscanf(f_in, "%lf ", &(g->links_val[i][j]));
        }
    }
    g->exp_calc=(double *)malloc((max_deg+1)*sizeof(double));
    g->max_deg=max_deg+1;
	fclose(f_in);	
}

void read_teacher(char *filename, graph *g) {
	int i, j;
	FILE *f_in;
	
	f_in=fopen(filename, "r");
	
	fscanf(f_in, "%i\n", &(g->n)); // first, number of nodes
    g->fields=(double *)malloc((g->n)*sizeof(double));
    for(i=0;i<g->n;i++) {
        fscanf(f_in, "%lf ", &(g->fields[i]));
    }
	fclose(f_in);		
}


void clear_graph(graph *g) {
    int i;
        
    for(i=0;i<g->n;i++) {
        g->val[i]=(int)gsl_rng_uniform_int(r, 2);
    }
    
}

void delete_graph(graph *g) {
    int i;
    
    for(i=0;i<g->n;i++) {
        free(g->links[i]);
    }
    free(g->val);
    free(g->count);
    free(g);
}

double abs_avg(graph *g) { // for each module, get the average value within
    double tot;
    int i;
    
    tot=0;
    for(i=0;i<g->n;i++) {
        // tot += 2.0*((double)g->val[i]-0.5);
        tot += (double)g->val[i];
    }
    return (tot/((double)g->n));
}

void paramagnetic_modules(graph *g) { // set up system in paramagnetic state
    int i, j;

    for(i=0;i<g->n_module;i++) {
        for(j=0;j<g->n_members[i];j++) {
            g->val[g->modules[i][j]]=fmod(g->modules[i][j],2);
        }
    }
}

void fix_all_true(graph *g) { // flip one cluster to the opposite of the average
    int i, j;

    for(i=0;i<g->n;i++) {
        g->val[i]=1;
    }
}

void fix_module_false(graph *g, int module_named) { // flip one cluster to the opposite of the average
    int i, j, flip_state=0;

    if (abs_avg(g) < 0) {
        flip_state=1;
    }
    for(i=0;i<g->n_members[module_named];i++) {
        g->val[g->modules[module_named][i]]=flip_state;
    }
}

void fix_random_module_false(graph *g, int module_named) { // flip one cluster to the opposite of the average
    int i, j, flip_state=0;

    if (abs_avg(g) < 0) {
        flip_state=1;
    }
    for(i=0;i<g->n_members[module_named];i++) {
        g->val[(int)gsl_rng_uniform_int(r, g->n)]=flip_state;
    }
}

double non_axiom_truth(graph *g) {
    int i;
    double running=0;
    
    for(i=0;i<g->n;i++) {
        if (g->axioms[i] == 0) {
            running += g->val[i];
        }
    }
    
    return running/((double)(g->n-g->n_axioms));
}

double axiom_truth(graph *g) {
    int i;
    double running=0;
    
    for(i=0;i<g->n;i++) {
        if (g->axioms[i] == 1) {
            if (g->val[i] == 1) {
                running += 1;
            }
        }
    }
    
    return running/((double)(g->n_axioms));
}

double abs_avg_modules(graph *g) { // for each module, get the average value within
    double running, tot;
    int i, j;
    
    tot=0;
    for(i=0;i<g->n_module;i++) {
        running=0;
        for(j=0;j<g->n_members[i];j++) {
            // running += 2.0*((double)g->val[g->modules[i][j]]-0.5);
            running += (double)g->val[g->modules[i][j]];
        }
        tot += fabs(running/((double)g->n_members[i])); // this should be between zero and one
    }
    return (tot/((double)g->n_module));
}

double avg_theorems(graph *g) {
    double running=0;
    int i;
    
    for(i=0;i<g->n;i++) {
        if (g->theorems[i] == 1) {
            running += g->val[i];
        }
    }
    
    return running/((double)g->n_theorems);
}

double avg_pagerank(graph *g) {
    double running=0;
    int i;
    
    for(i=0;i<g->n;i++) {
        running += (g->val[i])*g->pagerank[i];
    }
    
    return running;
}

double avg_modules(graph *g) { // for each module, get the average value within
    double running, tot;
    int i, j;
    
    tot=0;
    for(i=0;i<g->n_module;i++) {
        running=0;
        for(j=0;j<g->n_members[i];j++) {
            // running += 2.0*((double)g->val[g->modules[i][j]]-0.5);
            running += (double)g->val[g->modules[i][j]];
        }
        tot += (running/((double)g->n_members[i]));
    }
    return (tot/((double)g->n_module));
}

void read_modules(char *filename, char *filename_axiom, char *filename_theorem, char *filename_pagerank, graph *g) {
	int i, j, num_pageranks;
	FILE *f_in;
	// module file: number of modules; number of nodes in each module; list of nodes in each module

	f_in=fopen(filename, "r");
	
	fscanf(f_in, "%i\n", &(g->n_module));
	g->n_members=(int *)malloc((g->n_module)*sizeof(int));
	g->modules=(int **)malloc((g->n_module)*sizeof(int *));
    for(i=0;i<g->n_module;i++) {
        fscanf(f_in, "%i ", &(g->n_members[i]));
    }
    for(i=0;i<g->n_module;i++) {
        g->modules[i]=(int *)malloc((g->n_members[i])*sizeof(int));
        for(j=0;j<g->n_members[i];j++) {
            fscanf(f_in, "%i ", &(g->modules[i][j]));
        }
    }
	fclose(f_in);	

	f_in=fopen(filename_axiom, "r");
	fscanf(f_in, "%i\n", &(g->n_axioms)); // first, number of axioms
    g->axioms=(int *)malloc((g->n)*sizeof(int)); // 
    for(i=0;i<g->n;i++) {
        g->axioms[i]=0;
    }
    for(i=0;i<g->n_axioms;i++) {
        fscanf(f_in, "%i ", &j);
        g->axioms[j]=1;
    }
	fclose(f_in);	

	f_in=fopen(filename_theorem, "r");
	fscanf(f_in, "%i\n", &(g->n_theorems)); // first, number of axioms
    g->theorems=(int *)malloc((g->n)*sizeof(int)); // 
    for(i=0;i<g->n;i++) {
        g->theorems[i]=0;
    }
    for(i=0;i<g->n_theorems;i++) {
        fscanf(f_in, "%i ", &j);
        g->theorems[j]=1;
    }
	fclose(f_in);	

	f_in=fopen(filename_pagerank, "r");
	fscanf(f_in, "%i\n", &(num_pageranks)); // first, number of axioms
    g->pagerank=(double *)malloc((g->n)*sizeof(double)); // 
    for(i=0;i<g->n;i++) {
        g->pagerank[j]=0;
    }
    for(i=0;i<g->n;i++) {
        fscanf(f_in, "%i ", &j);
        fscanf(f_in, "%lf ", &(g->pagerank[j]));
        // printf("%i %e\n", j, g->pagerank[j]);
    }
	fclose(f_in);	
    
}

void set_axiom_prob(graph *g, double beta) {
    g->axiom_prob=1.0-2.0*(1-exp(2*beta)/(1+exp(2*beta)));
}

void print_graph(graph *g) {
    int i;
    
    for(i=0;i<g->n;i++) {
        printf("%i ", g->val[i]);       
    }
    printf("\n");
}

double avg_val(graph *g) {
    int i, tot=0;
    
    for(i=0;i<g->n;i++) {
        tot += g->val[i];
    }
    
    return (double)tot/(double)g->n;
}

double total_energy(graph *g) {
    int i, pos, tot=0;
    
    for(pos=0;pos<g->n;pos++) {
        for(i=0;i<g->count[pos];i++) {
            if (g->val[pos] == g->val[g->links[pos][i]]) { // if they're aligned, then that's better
                tot++;
            }
        }
    }
    
    return (double)tot/(double)g->n;
}

double total_energy_spin(graph *g) {
    int i, pos;
    double tot;
    
    for(pos=0;pos<g->n;pos++) {
        for(i=0;i<g->count[pos];i++) {
            tot += g->links_val[pos][i]*(2.0*g->val[pos]-1)*(2.0*g->val[g->links[pos][i]]-1);
        }
    }
    
    return (double)tot/(double)g->n;
}

double mean(double *list, int n) {
    int i;
    double tot=0;
    
    for(i=0;i<n;i++) {
        tot += list[i];
    }
    
    return tot/(double)n;
}

double variance(double *list, int n) {
    int i;
    double m, tot=0;
    
    m=mean(list, n);
    for(i=0;i<n;i++) {
        tot += (m-list[i])*(m-list[i]);
    }
    
    return tot/(double)n;
}

void update_graph(graph *g) {
    int i, pos;
    double prob, prob_exp, running=0;
    
    pos=(int)gsl_rng_uniform_int(r, g->n);
    
    if (g->links_val != NULL) {
        for(i=0;i<g->count[pos];i++) {
            running += g->links_val[pos][i]*(2.0*g->val[pos]-1)*(2.0*g->val[g->links[pos][i]]-1);
        }        
    } else {
        for(i=0;i<g->count[pos];i++) {
            running += (2.0*g->val[pos]-1)*(2.0*g->val[g->links[pos][i]]-1);
        }                
    }

    if (g->fields != NULL) {
        prob_exp=exp(g->beta*running+g->fields[pos]*(2*g->val[pos]-1));
    } else {
        prob_exp=exp(g->beta*running);        
    }
    
    prob=prob_exp/(prob_exp+1.0/prob_exp);          

    if (gsl_rng_uniform(r) > prob) {
        g->val[pos]=((g->val[pos]+1) % 2);
    }
}
