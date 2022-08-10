# this will do four examples of the outcomes of teaching, for tau at 2, 4, 8, and 10, and beta at 2 (a key figure in the Supplementary)
# it gives you both the hamming distance distribution for the tacit-teaching case, the copy-error case, and the same for the levenshtein

load "helper_functions.rb"
require 'levenshtein'
require "distribution"

beta=2.0 ## what the student is sitting at
n=30
n_keep=4

tau_hash=Hash.new

[2, 4, 8, 10].each { |tau|
  
  set=[]
  4.times { |pos|

    ## first, let's construct a facet network with 30 nodes...
    list=[]
    0.upto(n-2) { |i|
      (i+1).upto(n-1) { |j|
        val= 2*rand()-1
        list << [i,j,val]
        list << [j,i,val]
      }
    }
    ## list holds all the pairs; we'll make the network symmetric, and (here) we'll draw the links from a uniform distribution between -1 and 1.
    ## one of the referees asked about different network structures, so we can always vary this by changing the random number that is sampled for VAL

    ## we'll now write out the list of links in a format that our ising model code can handle
    file=File.new("DATA/node_weights.dat", 'w')
    file.write("#{n}\n")
    n.times { |i|
      list_of_links=list.select { |j| j[0] == i }.collect { |j| [j[1], j[2]] }
      file.write("#{list_of_links.length} #{list_of_links.flatten.join(" ")}\n")  
    }
    file.close

    ## now we'll run the ising model code on this network. The first thing we'll do is find all the (reasonably stable) equilibria
    count=Hash.new(0)
    1000.times {
      ans=`./CEU_ISING/ising -m DATA/node_weights.dat`.split("\n")
      str=ans[0].gsub(/[^0-9]/,"")
      val=ans[1].to_f
      count[str]+=1
      count[str.invert]+=1 ## both the string and its invert are equilibria (by the symmetry of all the interactions)
    }
    ## save only the systems that are found at least 5% of the time.
    count.keys.each { |i|
      if count[i] < 50 then
        count.delete(i)
      end
    };1

    ## here are the top equilibria -- just for simplicity, we'll only display half of them (because every equilibrium has a mirror image)
    top_equilibria=count.keys.sort { |i,j| count[j] <=> count[i] }.select { |i| 
      if i.scan(/0/).length != i.scan(/1/).length then
        i.scan(/0/).length <= i.scan(/1/).length
      else
        i[0] == "1"
      end
    }

    ## how do you teach?
    require 'parallel' ## this is a computationally expensive process -- let's use multiple cores
    n_proc=8

    current=top_equilibria[0].split("")
    equilibrium=top_equilibria[0].split("").collect { |i| i == "0" ? -1.0 : 1.0 }

    keep=[]
    best_keep=[]
    count=Hash.new(0)

    while(keep.length < n_keep) do
      running=[]
      0.upto(n) { |new_fix|
        if !keep.include?(new_fix) then
          keep += [new_fix]

          taught=Array.new(n) { |i|
            if keep.include?(i) then
              equilibrium[i]
            else
              0
            end
          }

          file=File.new("DATA/node_teacher.dat", 'w')
          file.write("#{n}\n#{taught.collect { |i| i*tau }.join(" ")}") ## note subtlety here -- we will have the teacher learn to teach with the same tau (whereas in simple_teacher.rb we allowed them to have super-strong tau)
          file.close

          n_samp=32*32
          hamming_list=Parallel.map(Array.new(n_samp) { nil }, :in_processes=>n_proc) {
            learned=`./CEU_ISING/ising -t DATA/node_weights.dat DATA/node_teacher.dat #{beta}`.split("\n")[0]
            count[learned] += 1

            current.hamming(learned.split(" "))
          }

          running << [keep.dup, n-hamming_list.mean, hamming_list.select { |i| i < 5 }.length*1.0/hamming_list.length]
          # print "#{keep}: #{hamming_list.mean}; #{hamming_list.select { |i| i == 0 }.length*1.0/hamming_list.length}\n"
          keep=keep[0..-2]
        end
      }
      print "Best node set to teach: #{running.sort { |i,j| j[1] <=> i[1] }[0][0]}; #{(running.sort { |i,j| j[1] <=> i[1] }[0][2]*100).round}% of students learn within 5 hamming steps.\n"
      keep=running.sort { |i,j| j[1] <=> i[1] }[0][0]
      best_keep=keep.dup
    end

    ### now experiment with teaching outcomes
    taught=Array.new(n) { |i|
      if best_keep.include?(i) then
        equilibrium[i]
      else
        0
      end
    }

    file=File.new("DATA/node_teacher.dat", 'w')
    file.write("#{n}\n#{taught.collect { |i| i*tau }.join(" ")}")
    file.close

    outcome_list=Parallel.map(Array.new(32*32*32) { nil }, :in_processes=>n_proc) {
      learned=`./CEU_ISING/ising -t DATA/node_weights.dat DATA/node_teacher.dat #{beta}`.split("\n")[0]
    };1

    distances=outcome_list.collect { |i| [current.hamming(i.split(" ")), Levenshtein.distance(current.join(""), i.split(" ").join(""))] };1

    p=distances.collect { |i| i[0] }.mean/30.0 ## probability of a flip in any particular facet
    def n_choose_k(n, k)
      Math.factorial(n) / (Math.factorial(k) * Math.factorial(n - k))
    end
    r=Array.new(31) { |i| n_choose_k(n, i)*(p**i)*(1-p)**(n-i) }
    rp=Array.new(31) { |i| distances.select { |j| j[0] == i }.length*1.0/distances.length }
  
    simulated_copy=Array.new(32*32*32) {
      Levenshtein.distance(current.join(""), Array.new(30) { |i| rand < (1-p) ? current[i] : (current[i] == "1" ? "0" : "1")}.join(""))
    };1
    rl=Array.new(31) { |i| simulated_copy.select { |j| j == i }.length*1.0/simulated_copy.length }
    rpl=Array.new(31) { |i| distances.select { |j| j[1] == i }.length*1.0/distances.length }

    set << [r, rp, rl, rpl]
    print "#{p}\n"
    print "#{set[-1]}\n"
  }
  
  tau_hash[tau]=set
}

## an example when I run it, this is the start so it's doing a tau=2 case, students aren't great.
# Best node set to teach: [14]; 30% of students learn within 5 hamming steps.
# Best node set to teach: [14, 24]; 32% of students learn within 5 hamming steps.
# Best node set to teach: [14, 24, 13]; 49% of students learn within 5 hamming steps.
# Best node set to teach: [14, 24, 13, 21]; 55% of students learn within 5 hamming steps.
# 0.2647430419921875
# [[9.844060918897219e-05, 0.00106336156557565, 0.0055518071632770305, 0.01865763364615091, 0.04534670604597767, 0.08490524137904513, 0.12738217820176526, 0.15725602159518962, 0.16279105772670516, 0.1432834823512721, 0.108342994378659, 0.07092895421354273, 0.04043722301058328, 0.0201602488064757, 0.008814591391648797, 0.003385449346784266, 0.0011428073063649532, 0.0003388734423059282, 8.812391707729028e-05, 2.0040421422354852e-05, 3.968761043070316e-06, 6.804889352848132e-07, 1.0023659565945974e-07, 1.2553761423928488e-08, 1.3183966197874584e-09, 1.139312164129832e-10, 7.889051701987775e-12, 4.208297567911995e-13, 1.623510404283005e-14, 4.031554040085781e-16, 4.8387885301130435e-18], [0.470306396484375, 0.046356201171875, 0.001190185546875, 0.000762939453125, 0.001495361328125, 0.013671875, 0.00634765625, 0.003570556640625, 0.003021240234375, 0.01104736328125, 0.020904541015625, 0.094970703125, 0.004852294921875, 0.012939453125, 0.0810546875, 0.01153564453125, 0.044097900390625, 0.00506591796875, 0.00994873046875, 0.009368896484375, 0.00579833984375, 0.0601806640625, 0.009735107421875, 0.005096435546875, 0.00054931640625, 0.001617431640625, 0.0001220703125, 6.103515625e-05, 9.1552734375e-05, 0.005828857421875, 0.05841064453125], [3.0517578125e-05, 0.00115966796875, 0.005462646484375, 0.019439697265625, 0.0535888671875, 0.1031494140625, 0.162689208984375, 0.1923828125, 0.184844970703125, 0.137725830078125, 0.08392333984375, 0.03778076171875, 0.013519287109375, 0.0032958984375, 0.00091552734375, 9.1552734375e-05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], [0.470306396484375, 0.046356201171875, 0.001190185546875, 0.000762939453125, 0.001495361328125, 0.013671875, 0.006439208984375, 0.010528564453125, 0.10552978515625, 0.03277587890625, 0.007781982421875, 0.060882568359375, 0.019500732421875, 0.1029052734375, 0.05224609375, 0.008941650390625, 0.058685302734375, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]]
# ....
# the first element of the list is distribution of Hamming distances the copy-error model (e.g., 9x10^-5 of the samples had a Hamming distance of zero in the copy error...), the second element of the list is the tacit-teaching, the third and fourth are the same except using Levenshtein distance.