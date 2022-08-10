# a nice way to interact with this code is to start a ruby shell (I use 2.5) and then type:
# source "construct_spin.rb"

load "helper_functions.rb"

## first, let's construct a facet network with 30 nodes...
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
10000.times {
  ans=`./CEU_ISING/ising -m DATA/node_weights.dat`.split("\n")
  str=ans[0].gsub(/[^0-9]/,"")
  val=ans[1].to_f
  count[str]+=1
  count[str.invert]+=1 ## both the string and its invert are equilibria (by the symmetry of all the interactions)
}
## save only the systems that are found at least 0.1% of the time.
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

print top_equilibria.collect { |i| i+": #{count[i]/10000.0}" }.join("\n")

## when i ran it today, here's what I got... look at that spectrum of equilibria, totally a paper in there about spin-glass landscapes, total freebie
# 100111111100000001110010111000: 0.1246
# 100110111010001101000110110001: 0.1053
# 100110111010001001110110111000: 0.0983
# 100110111010001101010110111000: 0.0661
# 011011000111010010011011011110: 0.065
# 101100100001111111100100100001: 0.0452
# 011011000111010010111011001111: 0.0418
# 011111010101010000111011111110: 0.027
# 100011111110000010010010111100: 0.0243
# 011101011101110000111111001111: 0.0234
# 011101011111111000111111001111: 0.0208
# 011011111111110010111001001110: 0.0178
# 011001001101110010011101000111: 0.0175
# 111011000101010001111011111111: 0.0171
# 011101010101110000111001101110: 0.0154
# 010011011110110010011011011110: 0.0144
# 100011111110000011010010111000: 0.013
# 100111111110101000110110111100: 0.0114
# 010010000111010000111011011111: 0.0113
# 011111111101110010111011011110: 0.0111
# 101111111101111010110011111110: 0.0095
# 000011111110100010010011011110: 0.009
# 100011111110100010010011011100: 0.009
# 101101111101111010110110100101: 0.0085
# 011010000101010000111011111110: 0.0084
# 101111111101100010110010111110: 0.008
# 010011111111010010011011011110: 0.0075
# 101101010000111101001001110011: 0.0072
# 100111111111101010110110101100: 0.0067
# 000110111111101010110110101100: 0.0065
# 100111111100100000110110111100: 0.0061
# 011101000101010001111011111111: 0.0054
# 101111111101101010110110101100: 0.0054
# 000111111110100010010111011100: 0.0052
# 010011111110010010011011011100: 0.0052
# 100111111100101000110110111000: 0.0052