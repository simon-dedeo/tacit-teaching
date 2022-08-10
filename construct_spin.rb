## untutored.rb is a simple guide to how to construct a facet network, how to load it into the raw CEU_ISING code, and how to 
## 

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


