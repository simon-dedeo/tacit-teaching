## how do you teach?
## first, run "construct_spin.rb" so that you have a network you're interested in, and an equilibrium you care about

require 'parallel' ## this is a computationally expensive process -- let's use multiple cores
n_proc=8 ## how many processors do you have

tau=20.0 ## vary this if you like -- but it doesn't have a huge effect on the final set of nodes found to teach with
beta=2.0 ## what the student is sitting at
n=30

n_keep=4 ## max number of teaching interventions

current=top_equilibria[0].split("") ## choosing zero here just means "take the equilibrium with the largest basin", which usually is easy to teach, but there aren't huge differences for the top-ranked ones.
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
      print "Try teaching set #{keep}: Avg dist #{hamming_list.mean}; Frac within 5 steps: #{hamming_list.select { |i| i < 5 }.length*1.0/hamming_list.length}; Frac precisely correct #{hamming_list.select { |i| i == 0 }.length*1.0/hamming_list.length}\n"
      keep=keep[0..-2]
    end
  }
  ## you can try picking the best by average Hamming distance, by Frac within 5 steps, by Frac precisely correct -- it can get tricky, because sometimes it can't find a good hit early
  print "Best node set to teach: #{running.sort { |i,j| j[1] <=> i[1] }[0][0]}; average dist #{n-(running.sort { |i,j| j[1] <=> i[1] }[0][1])} #{(running.sort { |i,j| j[1] <=> i[1] }[0][2]*100).round}% of students learn within 5 hamming steps.\n"
  keep=running.sort { |i,j| j[1] <=> i[1] }[0][0]
  best_keep=keep.dup
end

## here's an example of what I get when I run this, after running the construct_spin.rb code. Look at those clever animals!

# Try teaching set [0]: Avg dist 12.884765625; Frac within 5 steps: 0.208984375; Frac precisely correct 0.1787109375
# Try teaching set [1]: Avg dist 10.908203125; Frac within 5 steps: 0.232421875; Frac precisely correct 0.193359375
# Try teaching set [2]: Avg dist 10.880859375; Frac within 5 steps: 0.2255859375; Frac precisely correct 0.1826171875
# Try teaching set [3]: Avg dist 10.9951171875; Frac within 5 steps: 0.201171875; Frac precisely correct 0.16015625
# Try teaching set [4]: Avg dist 10.595703125; Frac within 5 steps: 0.2177734375; Frac precisely correct 0.1796875
# Try teaching set [5]: Avg dist 9.5283203125; Frac within 5 steps: 0.3046875; Frac precisely correct 0.251953125
# Try teaching set [6]: Avg dist 12.509765625; Frac within 5 steps: 0.2802734375; Frac precisely correct 0.21484375
# Try teaching set [7]: Avg dist 9.6171875; Frac within 5 steps: 0.2275390625; Frac precisely correct 0.197265625
# Try teaching set [8]: Avg dist 12.7958984375; Frac within 5 steps: 0.2255859375; Frac precisely correct 0.1806640625
# Try teaching set [9]: Avg dist 12.13671875; Frac within 5 steps: 0.3642578125; Frac precisely correct 0.283203125
# Try teaching set [10]: Avg dist 13.36328125; Frac within 5 steps: 0.265625; Frac precisely correct 0.205078125
# Try teaching set [11]: Avg dist 11.951171875; Frac within 5 steps: 0.2314453125; Frac precisely correct 0.1806640625
# Try teaching set [12]: Avg dist 10.451171875; Frac within 5 steps: 0.3505859375; Frac precisely correct 0.2861328125
# Try teaching set [13]: Avg dist 15.4638671875; Frac within 5 steps: 0.150390625; Frac precisely correct 0.142578125
# Try teaching set [14]: Avg dist 10.916015625; Frac within 5 steps: 0.2021484375; Frac precisely correct 0.158203125
# Try teaching set [15]: Avg dist 12.4013671875; Frac within 5 steps: 0.271484375; Frac precisely correct 0.2158203125
# Try teaching set [16]: Avg dist 9.943359375; Frac within 5 steps: 0.390625; Frac precisely correct 0.3115234375
# Try teaching set [17]: Avg dist 12.236328125; Frac within 5 steps: 0.1884765625; Frac precisely correct 0.14453125
# Try teaching set [18]: Avg dist 11.8779296875; Frac within 5 steps: 0.3134765625; Frac precisely correct 0.244140625
# Try teaching set [19]: Avg dist 12.9150390625; Frac within 5 steps: 0.265625; Frac precisely correct 0.2294921875
# Try teaching set [20]: Avg dist 12.8798828125; Frac within 5 steps: 0.2744140625; Frac precisely correct 0.22265625
# Try teaching set [21]: Avg dist 12.1640625; Frac within 5 steps: 0.234375; Frac precisely correct 0.1875
# Try teaching set [22]: Avg dist 11.6279296875; Frac within 5 steps: 0.2265625; Frac precisely correct 0.18359375
# Try teaching set [23]: Avg dist 11.318359375; Frac within 5 steps: 0.2421875; Frac precisely correct 0.1904296875
# Try teaching set [24]: Avg dist 11.224609375; Frac within 5 steps: 0.2138671875; Frac precisely correct 0.1689453125
# Try teaching set [25]: Avg dist 11.720703125; Frac within 5 steps: 0.2763671875; Frac precisely correct 0.2255859375
# Try teaching set [26]: Avg dist 11.2353515625; Frac within 5 steps: 0.2333984375; Frac precisely correct 0.1904296875
# Try teaching set [27]: Avg dist 10.8623046875; Frac within 5 steps: 0.3486328125; Frac precisely correct 0.29296875
# Try teaching set [28]: Avg dist 13.4423828125; Frac within 5 steps: 0.30078125; Frac precisely correct 0.2490234375
# Try teaching set [29]: Avg dist 10.9755859375; Frac within 5 steps: 0.2265625; Frac precisely correct 0.173828125
# Try teaching set [30]: Avg dist 14.5654296875; Frac within 5 steps: 0.1748046875; Frac precisely correct 0.1416015625
# Best node set to teach: [5]; average dist 9.5283203125 30% of students learn within 5 hamming steps.
# Try teaching set [5, 0]: Avg dist 7.3310546875; Frac within 5 steps: 0.3427734375; Frac precisely correct 0.2724609375
# Try teaching set [5, 1]: Avg dist 5.80078125; Frac within 5 steps: 0.4970703125; Frac precisely correct 0.404296875
# Try teaching set [5, 2]: Avg dist 7.5263671875; Frac within 5 steps: 0.33203125; Frac precisely correct 0.259765625
# Try teaching set [5, 3]: Avg dist 7.572265625; Frac within 5 steps: 0.337890625; Frac precisely correct 0.255859375
# Try teaching set [5, 4]: Avg dist 6.955078125; Frac within 5 steps: 0.3271484375; Frac precisely correct 0.26171875
# Try teaching set [5, 6]: Avg dist 6.978515625; Frac within 5 steps: 0.42578125; Frac precisely correct 0.3349609375
# Try teaching set [5, 7]: Avg dist 6.427734375; Frac within 5 steps: 0.3994140625; Frac precisely correct 0.3154296875
# Try teaching set [5, 8]: Avg dist 7.548828125; Frac within 5 steps: 0.43359375; Frac precisely correct 0.3583984375
# Try teaching set [5, 9]: Avg dist 3.9794921875; Frac within 5 steps: 0.6357421875; Frac precisely correct 0.517578125
# Try teaching set [5, 10]: Avg dist 8.748046875; Frac within 5 steps: 0.4072265625; Frac precisely correct 0.314453125
# Try teaching set [5, 11]: Avg dist 9.3291015625; Frac within 5 steps: 0.28515625; Frac precisely correct 0.2265625
# Try teaching set [5, 12]: Avg dist 8.1201171875; Frac within 5 steps: 0.4267578125; Frac precisely correct 0.34765625
# Try teaching set [5, 13]: Avg dist 10.2880859375; Frac within 5 steps: 0.2333984375; Frac precisely correct 0.2265625
# Try teaching set [5, 14]: Avg dist 7.2158203125; Frac within 5 steps: 0.3583984375; Frac precisely correct 0.294921875
# Try teaching set [5, 15]: Avg dist 9.625; Frac within 5 steps: 0.3046875; Frac precisely correct 0.24609375
# Try teaching set [5, 16]: Avg dist 7.8623046875; Frac within 5 steps: 0.421875; Frac precisely correct 0.341796875
# Try teaching set [5, 17]: Avg dist 7.1279296875; Frac within 5 steps: 0.345703125; Frac precisely correct 0.2822265625
# Try teaching set [5, 18]: Avg dist 3.6484375; Frac within 5 steps: 0.6357421875; Frac precisely correct 0.490234375
# Try teaching set [5, 19]: Avg dist 7.14453125; Frac within 5 steps: 0.4609375; Frac precisely correct 0.359375
# Try teaching set [5, 20]: Avg dist 6.1884765625; Frac within 5 steps: 0.4580078125; Frac precisely correct 0.3671875
# Try teaching set [5, 21]: Avg dist 9.3681640625; Frac within 5 steps: 0.2802734375; Frac precisely correct 0.2392578125
# Try teaching set [5, 22]: Avg dist 6.1337890625; Frac within 5 steps: 0.423828125; Frac precisely correct 0.3330078125
# Try teaching set [5, 23]: Avg dist 5.65234375; Frac within 5 steps: 0.4931640625; Frac precisely correct 0.3701171875
# Try teaching set [5, 24]: Avg dist 7.4892578125; Frac within 5 steps: 0.34765625; Frac precisely correct 0.2900390625
# Try teaching set [5, 25]: Avg dist 8.4951171875; Frac within 5 steps: 0.357421875; Frac precisely correct 0.2939453125
# Try teaching set [5, 26]: Avg dist 6.5703125; Frac within 5 steps: 0.3720703125; Frac precisely correct 0.296875
# Try teaching set [5, 27]: Avg dist 4.052734375; Frac within 5 steps: 0.62890625; Frac precisely correct 0.5
# Try teaching set [5, 28]: Avg dist 7.30859375; Frac within 5 steps: 0.498046875; Frac precisely correct 0.390625
# Try teaching set [5, 29]: Avg dist 6.34375; Frac within 5 steps: 0.4072265625; Frac precisely correct 0.328125
# Try teaching set [5, 30]: Avg dist 9.42578125; Frac within 5 steps: 0.314453125; Frac precisely correct 0.236328125
# Best node set to teach: [5, 18]; average dist 3.6484375 64% of students learn within 5 hamming steps.
# Try teaching set [5, 18, 0]: Avg dist 2.0849609375; Frac within 5 steps: 0.8037109375; Frac precisely correct 0.658203125
# Try teaching set [5, 18, 1]: Avg dist 2.7421875; Frac within 5 steps: 0.724609375; Frac precisely correct 0.57421875
# Try teaching set [5, 18, 2]: Avg dist 2.7001953125; Frac within 5 steps: 0.7177734375; Frac precisely correct 0.5595703125
# Try teaching set [5, 18, 3]: Avg dist 3.1591796875; Frac within 5 steps: 0.669921875; Frac precisely correct 0.546875
# Try teaching set [5, 18, 4]: Avg dist 3.0283203125; Frac within 5 steps: 0.6875; Frac precisely correct 0.5576171875
# Try teaching set [5, 18, 6]: Avg dist 2.451171875; Frac within 5 steps: 0.779296875; Frac precisely correct 0.630859375
# Try teaching set [5, 18, 7]: Avg dist 2.4169921875; Frac within 5 steps: 0.7421875; Frac precisely correct 0.595703125
# Try teaching set [5, 18, 8]: Avg dist 3.4228515625; Frac within 5 steps: 0.666015625; Frac precisely correct 0.5146484375
# Try teaching set [5, 18, 9]: Avg dist 2.158203125; Frac within 5 steps: 0.8076171875; Frac precisely correct 0.6298828125
# Try teaching set [5, 18, 10]: Avg dist 3.2744140625; Frac within 5 steps: 0.69921875; Frac precisely correct 0.556640625
# Try teaching set [5, 18, 11]: Avg dist 2.7705078125; Frac within 5 steps: 0.708984375; Frac precisely correct 0.5693359375
# Try teaching set [5, 18, 12]: Avg dist 2.5126953125; Frac within 5 steps: 0.744140625; Frac precisely correct 0.5947265625
# Try teaching set [5, 18, 13]: Avg dist 4.6748046875; Frac within 5 steps: 0.5166015625; Frac precisely correct 0.5029296875
# Try teaching set [5, 18, 14]: Avg dist 2.732421875; Frac within 5 steps: 0.71875; Frac precisely correct 0.5673828125
# Try teaching set [5, 18, 15]: Avg dist 3.0478515625; Frac within 5 steps: 0.68359375; Frac precisely correct 0.55078125
# Try teaching set [5, 18, 16]: Avg dist 2.3896484375; Frac within 5 steps: 0.755859375; Frac precisely correct 0.62109375
# Try teaching set [5, 18, 17]: Avg dist 3.171875; Frac within 5 steps: 0.6669921875; Frac precisely correct 0.5283203125
# Try teaching set [5, 18, 19]: Avg dist 2.1240234375; Frac within 5 steps: 0.8134765625; Frac precisely correct 0.6494140625
# Try teaching set [5, 18, 20]: Avg dist 2.21875; Frac within 5 steps: 0.787109375; Frac precisely correct 0.62890625
# Try teaching set [5, 18, 21]: Avg dist 2.986328125; Frac within 5 steps: 0.673828125; Frac precisely correct 0.5673828125
# Try teaching set [5, 18, 22]: Avg dist 2.3359375; Frac within 5 steps: 0.763671875; Frac precisely correct 0.6103515625
# Try teaching set [5, 18, 23]: Avg dist 2.609375; Frac within 5 steps: 0.740234375; Frac precisely correct 0.5947265625
# Try teaching set [5, 18, 24]: Avg dist 3.0322265625; Frac within 5 steps: 0.68359375; Frac precisely correct 0.5341796875
# Try teaching set [5, 18, 25]: Avg dist 2.9990234375; Frac within 5 steps: 0.69921875; Frac precisely correct 0.568359375
# Try teaching set [5, 18, 26]: Avg dist 2.5546875; Frac within 5 steps: 0.7578125; Frac precisely correct 0.5908203125
# Try teaching set [5, 18, 27]: Avg dist 2.1083984375; Frac within 5 steps: 0.8154296875; Frac precisely correct 0.66015625
# Try teaching set [5, 18, 28]: Avg dist 2.3388671875; Frac within 5 steps: 0.8017578125; Frac precisely correct 0.63671875
# Try teaching set [5, 18, 29]: Avg dist 2.943359375; Frac within 5 steps: 0.6953125; Frac precisely correct 0.5546875
# Try teaching set [5, 18, 30]: Avg dist 3.830078125; Frac within 5 steps: 0.619140625; Frac precisely correct 0.4892578125
# Best node set to teach: [5, 18, 0]; average dist 2.0849609375 80% of students learn within 5 hamming steps.
# Try teaching set [5, 18, 0, 1]: Avg dist 0.6103515625; Frac within 5 steps: 0.9541015625; Frac precisely correct 0.7890625
# Try teaching set [5, 18, 0, 2]: Avg dist 1.33984375; Frac within 5 steps: 0.869140625; Frac precisely correct 0.7080078125
# Try teaching set [5, 18, 0, 3]: Avg dist 1.4287109375; Frac within 5 steps: 0.8583984375; Frac precisely correct 0.7109375
# Try teaching set [5, 18, 0, 4]: Avg dist 1.5244140625; Frac within 5 steps: 0.8544921875; Frac precisely correct 0.6708984375
# Try teaching set [5, 18, 0, 6]: Avg dist 2.42578125; Frac within 5 steps: 0.7705078125; Frac precisely correct 0.6171875
# Try teaching set [5, 18, 0, 7]: Avg dist 1.25390625; Frac within 5 steps: 0.8828125; Frac precisely correct 0.7041015625
# Try teaching set [5, 18, 0, 8]: Avg dist 0.90625; Frac within 5 steps: 0.9208984375; Frac precisely correct 0.7548828125
# Try teaching set [5, 18, 0, 9]: Avg dist 2.1337890625; Frac within 5 steps: 0.7978515625; Frac precisely correct 0.634765625
# Try teaching set [5, 18, 0, 10]: Avg dist 0.7080078125; Frac within 5 steps: 0.9580078125; Frac precisely correct 0.76953125
# Try teaching set [5, 18, 0, 11]: Avg dist 1.076171875; Frac within 5 steps: 0.8994140625; Frac precisely correct 0.740234375
# Try teaching set [5, 18, 0, 12]: Avg dist 0.34765625; Frac within 5 steps: 0.978515625; Frac precisely correct 0.8154296875
# Try teaching set [5, 18, 0, 13]: Avg dist 2.4482421875; Frac within 5 steps: 0.76171875; Frac precisely correct 0.73046875
# Try teaching set [5, 18, 0, 14]: Avg dist 1.275390625; Frac within 5 steps: 0.8798828125; Frac precisely correct 0.6748046875
# Try teaching set [5, 18, 0, 15]: Avg dist 0.8369140625; Frac within 5 steps: 0.9267578125; Frac precisely correct 0.775390625
# Try teaching set [5, 18, 0, 16]: Avg dist 0.2275390625; Frac within 5 steps: 0.9951171875; Frac precisely correct 0.83203125
# Try teaching set [5, 18, 0, 17]: Avg dist 1.5146484375; Frac within 5 steps: 0.8486328125; Frac precisely correct 0.69921875
# Try teaching set [5, 18, 0, 19]: Avg dist 1.9580078125; Frac within 5 steps: 0.81640625; Frac precisely correct 0.646484375
# Try teaching set [5, 18, 0, 20]: Avg dist 2.462890625; Frac within 5 steps: 0.7587890625; Frac precisely correct 0.6123046875
# Try teaching set [5, 18, 0, 21]: Avg dist 1.357421875; Frac within 5 steps: 0.8642578125; Frac precisely correct 0.7001953125
# Try teaching set [5, 18, 0, 22]: Avg dist 2.013671875; Frac within 5 steps: 0.8173828125; Frac precisely correct 0.63671875
# Try teaching set [5, 18, 0, 23]: Avg dist 0.6767578125; Frac within 5 steps: 0.9443359375; Frac precisely correct 0.7607421875
# Try teaching set [5, 18, 0, 24]: Avg dist 2.0390625; Frac within 5 steps: 0.8046875; Frac precisely correct 0.64453125
# Try teaching set [5, 18, 0, 25]: Avg dist 0.1884765625; Frac within 5 steps: 0.9990234375; Frac precisely correct 0.818359375
# Try teaching set [5, 18, 0, 26]: Avg dist 1.861328125; Frac within 5 steps: 0.8271484375; Frac precisely correct 0.666015625
# Try teaching set [5, 18, 0, 27]: Avg dist 1.8037109375; Frac within 5 steps: 0.833984375; Frac precisely correct 0.6826171875
# Try teaching set [5, 18, 0, 28]: Avg dist 1.9951171875; Frac within 5 steps: 0.8251953125; Frac precisely correct 0.666015625
# Try teaching set [5, 18, 0, 29]: Avg dist 1.9013671875; Frac within 5 steps: 0.8125; Frac precisely correct 0.654296875
# Try teaching set [5, 18, 0, 30]: Avg dist 2.169921875; Frac within 5 steps: 0.8017578125; Frac precisely correct 0.64453125
# Best node set to teach: [5, 18, 0, 25]; average dist 0.1884765625 100% of students learn within 5 hamming steps.
