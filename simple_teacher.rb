## how do you teach?
require 'parallel' ## this is a computationally expensive process -- let's use multiple cores
n_proc=8

tau=20.0 ## vary this if you like -- but it doesn't have a huge effect on the final set of nodes found to teach with
beta=2.0 ## what the student is sitting at
n=30

n_keep=4

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
