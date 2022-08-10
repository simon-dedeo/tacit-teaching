# sudo gem2.5 install levenshtein-ffi
# sudo gem2.5 install levenshtein
# sudo gem2.5 install parallel
# sudo gem2.5 install distribution

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
          file.write("#{n}\n#{taught.collect { |i| i*tau }.join(" ")}")
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

    # irb(main):608:0> "011010001010000001001111010100".hamming("100101001101100010010111100110")
    # => 17
    # irb(main):609:0> Levenshtein.distance("011010001010000001001111010100", "100101001101100010010111100110")
    # => 8

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
  }
  
  tau_hash[tau]=set
}


