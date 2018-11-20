title: ScPo In the Clouds
class: animation-fade
author: Florian Oswald, SciencesPo Paris 2018
layout: true

<!-- This slide will serve as the base layout for all your slides -->
.bottom-bar[
  {{author}}
]

---

class: impact

# {{title}}
## HPC on AWS

---

class: impact

# Follow me 
## [https://floswald.github.io/miscellany/](https://floswald.github.io/miscellany/)

All materials are available on [github](https://github.com/floswald/cluster).

---

# What is AWS

* Amazon Web Services
* Can get 1 year free
* Building an HPC cluster used to be a *mighty hack*.


## You never had it so easy

* The [cfncluster](https://cfncluster.readthedocs.io/en/latest/index.html#) library changed our lives.
* (There is also [aws-parallelcluster](https://github.com/aws/aws-parallelcluster) which seems to do the same thing.)

--

* Your Uni has no money for a cluster?
    ```
    cfncluster create hellocluster   # easy!
    ```


---

## Costs

* Here are the prices for spot instances in the Paris region (per hour):

.col-6[
type     |  unix             |  windows
:--------- | :--------------: | -----------:
t2.micro   | $0.004    |   $0.0086
t2.small   | $0.0079  |   $0.0171 
t2.medium  | $0.0158  |   $0.0338 
t2.large   | $0.0317  |   $0.0597 
t2.xlarge  | $0.0634  |   $0.1044 
t2.2xlarge | $0.1267  |   $0.1887 
t3.nano    | $0.0059  |   $0.0105 
]

--

.col-6[
* So, compute *time* is cheap.
* Careful with persistent memory (EBS) though!
* You pay for each GB/month.
* AWS provides very good cost monitoring with alerts.
]

---

# Why AWS?

* AWS is not the only cloud solution to do research computing.

--

* I use the google cloud for a research project, for example, and it's awesome.

--

* Missing elsewhere: `cfncluster`.

--

* Just to say: AWS is not the only solution and I don't endorse AWS as such.


---

# Let's get Cracking

Plan:

1. Launch cluster
2. (people who sent me SSH keys log on)
3. showcase `mpi` job in `C`
4. showcase parallel jobs in `julia`

---

# `Paris` cluster

* `cfncluster create mycluster` takes ca 15 mins.

--

* Here's the `cfncluster` config for the `Paris` cluster I created.
    ```
    [cluster paris]
    vpc_settings = public
    key_name = aws-paris
    compute_instance_type = t2.micro
    master_instance_type = t2.micro
    initial_queue_size = 3
    max_queue_size = 9
    ebs_settings = helloebs
    post_install = https://xxxxxxxxxxx.s3.amazonaws.com/myscript.sh
    ```

--

* There are [plenty more options](https://cfncluster.readthedocs.io/en/latest/configuration.html#configuration-options)


---

## Creating a Cluster

* This is the output after 15 minutes
```
➜  cfncluster create paris
Beginning cluster creation for cluster: paris
Creating stack named: cfncluster-paris
Status: cfncluster-paris - CREATE_COMPLETE                                      
MasterPublicIP: 52.47.129.72
ClusterUser: ec2-user
MasterPrivateIP: 172.31.1.143
```
* At this point it's running!

--

* And you are paying for it!!

---

# Using a cluster

* And here is how I can launch it (second time round)

--

* first, go to AWS console and launch master node

--

* second, on my laptop: `cfncluster start Paris`

--

* Check all are up on the AWS console and `qhost`

```
ec2-user@ip-172-31-1-143 hw_work]$ qhost
HOSTNAME                ARCH         NCPU NSOC NCOR NTHR  LOAD  MEMTOT  MEMUSE  SWAPTO  SWAPUS
----------------------------------------------------------------------------------------------
global                  -               -    -    -    -     -       -       -       -       -
ip-172-31-2-30          lx-amd64        1    1    1    1  0.03  985.8M  199.3M     0.0     0.0
ip-172-31-3-153         lx-amd64        1    1    1    1  0.02  985.8M  199.7M     0.0     0.0
ip-172-31-9-128         lx-amd64        1    1    1    1  0.05  985.8M  200.5M     0.0     0.0
```

---

## `hello_world_mpi.c`

* This is straight out of a [cfncluster tutorial](https://aws.amazon.com/getting-started/projects/deploy-elastic-hpc-cluster/)
* Very useful if you want to build your own cluster!
* I attached a HDD with is mapped at `/shared`:
    ```
    [ec2-user@ip-172-31-8-50 ~]$ ls /shared
    apps  bin  hw_work  juliapkg  lost+found
    ```
* I compiled the `hw.x` executable for you.
* Let's submit that to the SGE scheduler (installed by default!)

---

## `qsub hw.job`

```
[ec2-user@ip-172-31-8-50 hw_work]$ cd /shared/hw_work
[ec2-user@ip-172-31-8-50 hw_work]$ cat hw.job
#!/bin/sh
#$ -cwd
#$ -N helloworld
#$ -pe mpi 3
#$ -j y
date
/usr/lib64/openmpi/bin/mpirun ./hw.x > hello_all.out

[ec2-user@ip-172-31-8-50 hw_work]$ qsub hw.job
```



---

# A Julia Session

* Parallel is pretty easy with julia.
* we just need passwordless SSH between nodes.
* I installed julia for you (and me!)
* start julia!

```julia
[ec2-user@ip-172-31-8-50 hw_work]$ julia
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.0.0 (2018-08-08)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

julia> 
```

---

## Adding processes

```julia
julia> using Distributed  # parallel computing tools

# add three processes
julia> machine_ip = readlines(`qconf -sel`)
3-element Array{String,1}:
 "ip-172-31-2-30.eu-west-3.compute.internal" 
 "ip-172-31-3-153.eu-west-3.compute.internal"
 "ip-172-31-9-128.eu-west-3.compute.internal"

julia> mach_spec = [(i,:auto) for i in machine_ip]

julia> addprocs(mach_spec)   # easy enough?
3-element Array{Int64,1}:
  8
  9
 10

```

---

## Adding Code

```julia
@everywhere using LinearAlgebra

@everywhere function serial(x)
    map( n -> sum(svd(rand(n,n)).V) , [800 for i in 1:x])
end

@everywhere function parallel(x)
    pmap( n -> sum(svd(rand(n,n)).V) , [800 for i in 1:x])
end

# warm up the JIT
serial(1);
parallel(1);

```

---

## Running Code

```julia


# go!

julia> @time serial(64);
 26.599783 seconds (1.03 k allocations: 2.142 GiB, 1.06% gc time)

julia> @time parallel(64);
  9.998689 seconds (8.31 k allocations: 384.460 KiB)


```


---

# Autoscaling

* `cfncluster` is smart about adding more/less nodes.
* It runs a `cron` process every minute on the master to check queue-length and adds/removes compute nodes dynamically.
* We most of the time need a static cluster (i.e. no changes). Easy to achieve with options.

---

## Autoscaling Live

* Let's go wild and max out the cluster (max size is 10 nodes)
* All who are logged in run the last part of `script.jl`
