require 'parallel' ## this is a computationally expensive process -- let's use multiple cores
require 'random_graph'

include RandomGraph

load 'helper_functions.rb'

seq=[]

100.times {
  
  begin
    n=30
    list=[]
    0.upto(n-2) { |i|
      (i+1).upto(n-1) { |j|
        val= 2*rand()-1
        list << [i,j,val]
        list << [j,i,val]
      }
    }
    ## list holds all the pairs; we'll make the network symmetric, and (here) we'll draw the links from a uniform distribution between -1 and 1.
    ## one of the referees asked about different network structures, so we can always vary this by changing the random number that is sampled for VAL;
    ## for example, to do binary values, do 2*rand().round - 1

    ## here's how to simulate a Watts-Strogatz like connection (see Supplementary)
    # n=30
    # g = Graph.watts_strogatz(n, 5, 0.2)
    # while(g.number_of_components > 1) do ## make sure the network is connected (meaning that there aren't any lose nodes that require special teaching)
    #   g = Graph.watts_strogatz(n, 5, 0.2)
    # end
    #
    # list=[]
    # 0.upto(n-1) { |i|
    #     g.nodes[i].each { |j|
    #       val=2*rand()-1
    #       list << [i,j,val]
    #       list << [j,i,val]
    #     }
    # }
    ###

    ## we'll now write out the list of links in a format that our ising model code can handle
    file=File.new("DATA/node_weights_TEMP.dat", 'w')
    file.write("#{n}\n")
    n.times { |i|
      list_of_links=list.select { |j| j[0] == i }.collect { |j| [j[1], j[2]] }
      file.write("#{list_of_links.length} #{list_of_links.flatten.join(" ")}\n")  
    }
    file.close

    ## now we'll run the ising model code on this network. The first thing we'll do is find all the (reasonably stable) equilibria
    count=Hash.new(0)
    1000.times {
      ans=`./CEU_ISING/ising -m DATA/node_weights_TEMP.dat`.split("\n")
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

    current=top_equilibria[0].split("")
  rescue
    retry
  end
  equilibrium=top_equilibria[0].split("").collect { |i| i == "0" ? -1.0 : 1.0 }

  n_proc=8
  n_keep=4 # max number to try
  tau=20.0 ## play with these to see robustness effects
  beta=2.0 ## what the student is sitting at

  current=top_equilibria[0].split("")
  equilibrium=top_equilibria[0].split("").collect { |i| i == "0" ? -1.0 : 1.0 }

  keep=[]
  best_keep=[]
  count=Hash.new(0)

  set=[]
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

        file=File.new("DATA/node_teacher_TEMP.dat", 'w')
        file.write("#{n}\n#{taught.collect { |i| i*tau }.join(" ")}")
        file.close

        n_samp=32*32
        hamming_list=Parallel.map(Array.new(n_samp) { nil }, :in_processes=>n_proc) {
          learned=`./CEU_ISING/ising -t DATA/node_weights_TEMP.dat DATA/node_teacher_TEMP.dat #{beta}`.split("\n")[0]
          count[learned] += 1

          current.hamming(learned.split(" "))
        }

        running << [keep.dup, hamming_list.mean, hamming_list.select { |i| i < 1 }.length*1.0/hamming_list.length, hamming_list.select { |i| i < 2 }.length*1.0/hamming_list.length, hamming_list.select { |i| i < 5 }.length*1.0/hamming_list.length]
        # print "#{keep}: #{hamming_list.mean}; #{hamming_list.select { |i| i == 0 }.length*1.0/hamming_list.length}\n"
        keep=keep[0..-2]
      end
    }
    print "Best node set to teach: #{running.sort { |i,j| j[4] <=> i[4] }[0][0]}; #{(running.sort { |i,j| j[4] <=> i[4] }[0][2]*100).round}% of students learn within 5 hamming steps.\n"
    keep=running.sort { |i,j| j[4] <=> i[4] }[0][0]
    set << running.sort { |i,j| j[4] <=> i[4] }[0][1..-1]
    best_keep=keep.dup
  end

  seq << set

  print "#{seq[-1]}\n"
}


