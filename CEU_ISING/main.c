#include "ising.h"

// format of input:
// (1) name of connection network file
//  first, number of nodes
// then, for each node: (1) the number of links, (2) the links, in order
// (2) the external field values
// (3) the beta value

// -m [network connections] : find an equilibrium; sets beta to 100 and iterates quickly (quenching)
// network connection file looks like:
// 30 [number of nodes]
// then, each line:
// 29 1 -0.21777764869396488 2 -0.4431113117385348 3 0.24003862240765494 4 0.24290570259416522 5 0.7930081837781029 6 0.24841447192812027 7 0.10152296261374016 8 0.23274405969450873 9 0.7096532002057427 10 -0.8116278836116566 11 0.12165368547744837 12 0.12585217543274863 13 0.34167010768213624 14 -0.22580416626150268 15 0.5423362351922485 16 -0.87603984792302 17 0.7113561828852148 18 -0.43497872729299814 19 -0.6584906848719743 20 -0.7249059219147238 21 0.9273395484650953 22 0.835505313596062 23 0.9024479305524435 24 -0.7559460050113076 25 0.3412434708069383 26 -0.8338679234557875 27 -0.07365325599469341 28 -0.1604739564597535 29 0.06728980048860533

// -t [network connections] [intervention] [beta] : 

int main (int argc, char *argv[]) {
    graph *g;
    FILE *fn;
	unsigned long r_seed;
	const gsl_rng_type *T;
	gsl_rng_env_setup();
    int i,j,k,m,p,pos,n_run,n_betas,count;
    double *list, beta, beta_temp, energy_diff, running_abs_avg_modules, running_abs_avg, running_module_diff, running_random_diff, energy_module_false, energy_random_false, energy_all_true;
    double beta_sav, running_non_axioms, running_theorems, running_pagerank;
    
	fn = fopen("/dev/urandom", "rb"); 		
	if (fread(&r_seed, sizeof(r_seed), 1, fn) != 1) 
		exit(-1); /* Failed! */
	
	T=gsl_rng_default;
	r=gsl_rng_alloc(T);
	gsl_rng_set(r, r_seed);
    
    // g=init_graph();
    // read_graph(argv[1], g);
    // read_fields(argv[2], g);
    // beta=atof(argv[3]);
    // for(i=0;i<g->max_deg;i++) {
    //     g->exp_calc[i]=exp(-beta*(double)(i));
    // }
    // g->beta=beta;
    // 
    // clear_graph(g);
    // 
    // for(i=0;i<1000;i++) {
    //     update_graph(g);  
    // }
    // 
    // print_graph(g);        

	switch((int)argv[1][1]) {
		case 'm':
            g=init_graph();
            read_weights(argv[2], g);
            g->fields=NULL;

            clear_graph(g);
            // for(i=0;i<=1000;i++) {
            //     if ((i % 100) == 0) {
            //         beta=exp(log(100)*i/1000.0); // annealing schedule
            //         for(j=0;j<g->max_deg;j++) {
            //             g->exp_calc[j]=exp(-beta*(double)(j));
            //         }
            //     }
            //     g->beta=beta;
            //     update_graph(g);
            // }
            beta=100; // fix final value
            for(i=0;i<g->max_deg;i++) { // precompute the exponential functions
                g->exp_calc[i]=exp(-beta*(double)(i));
            }
            g->beta=beta;
            for(i=0;i<10000;i++) {
                update_graph(g);  
            }

            print_graph(g);        
            printf("%lf\n", total_energy_spin(g));
            break;
        case 't':
            g=init_graph();
            read_weights(argv[2], g);
            read_teacher(argv[3], g);
            beta_sav=atof(argv[4]);

            clear_graph(g);
			
			// START teaching annealing step -- COMMENT THIS OUT IF YOU WANT THE STUDENT TO BE DEEPLY UNCHILL
            for(i=0;i<=1000;i++) {
                if ((i % 100) == 0) {
                    beta=exp(log(beta_sav)*i/1000.0); // annealing schedule ...
                    for(j=0;j<g->max_deg;j++) {
                        g->exp_calc[j]=exp(-beta*(double)(j));
                    }
                }
                g->beta=beta;
                update_graph(g);
            }
			// FINISH TEACHING ANNEALING STEP
			
			g->beta=beta_sav;
            beta=beta_sav;
            for(i=0;i<g->max_deg;i++) {
                g->exp_calc[i]=exp(-beta*(double)(i));
            }
            for(i=0;i<1000;i++) { // first learn in the presence of the teacher
                update_graph(g);  
            }
            // free(g->fields);
            // g->fields=NULL;
            // for(i=0;i<1000;i++) { // then teacher leaves
            //     update_graph(g);  
            // }

            print_graph(g);        
            break;
    }
    

	exit(1);
}