
# julia test script

## demonstrate parallel speed up

# 1. start julia on the master

# 2. add three processes with ClusterManagers
using Distributed  # parallel computing tools
using ClusterManagers   # to interface cluster schedulers
addprocs_sge(3)  # doesn't work :-(

# but you said it's easy!

# 2.a add three processes
machine_ip = readlines(`qconf -sel`)

mach_spec = [(i,:auto) for i in machine_ip]
addprocs(mach_spec)   # easy enough?

# 3. let's load the LinearAlgebra library on all nodes
@everywhere using LinearAlgebra

# 4. let's define 2 version of a function on all nodes: serial and parallel
@everywhere serial(x) = map( n -> sum(svd(rand(n,n)).V) , [800 for i in 1:x])
@everywhere parallel(x) = pmap( n -> sum(svd(rand(n,n)).V) , [800 for i in 1:x])

# 5. warm up the JIT
serial(1);
parallel(1);

# 6. go!
@time serial(64);
@time parallel(64);


## demonstrate autoscaling

using ProgressMeter  # to print nice progress bar

function takes_time(ntasks::Int)
	p = Progress(ntasks)   # create a progress bar with ntasks to do
	# create a RemoteChannel with an entry for each task: true (done), or false (still working/waiting)
	channel = RemoteChannel(()->Channel{Bool}(ntasks), 1)

	@sync begin
	    # this task prints the progress bar
	    @async while take!(channel)
	        next!(p)
	    end

	    # this task does the computation
	    @async begin
	        @distributed (+) for i in 1:ntasks
	            sleep(10)  # each task takes 10 seconds
	            put!(channel, true)
	            i^2
	        end
	        put!(channel, false) # this tells the printing task to finish
	    end
	end
end


