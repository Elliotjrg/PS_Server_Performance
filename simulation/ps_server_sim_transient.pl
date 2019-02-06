#!/usr/bin/perl -w

###########################################
# 
# THIS PROGRAM IS USED TO PRINT OUT ALL   #
# JOB NUMBERS AND THE CURRENT MEAN        #
# RESPONSE TIME. WE CAN THEN FIND WHEN    #
# THE SYSTEM ACHIEVES STEADY STATE        #
#
###########################################




# COMP9334 Project
# PS Server Simulation FOR TRANSIENT
# 29/4/17
#
# Elliot Griffiths
# z3332776
# elliotjg@gmail.com



###########################################
# Initialising & setting parameters
###########################################

# Set the seed for pseudo-random number generation
srand(2);

# Simulation time
my $sim_time = 5000 + $ARGV[0];

# Set the number of servers running and find the frequency
my $servers = $ARGV[1];
my $watts = 2000;
my $power = $watts / $servers;
my $frequency = 1.25 + 0.31*(($power/200) - 1);

# T is the cumulative response time 
my $T = 0;
# Number of completed customers at the end of the simulation
my $N = 0;




###########################################
# Building framework for generating events
###########################################


# Set Mean arrival rate for generating exponentially distributed numbers, a_1k 
my $lambda = 7.2;
# Generate exponential distributed number
my $a_1k = (-log(1-rand(1))/$lambda);

# Setting range for uniformly distributed numbers, a_2k
my $maximum = 1.17;
my $minimum = 0.75;
# Generate uniformly distributed number in set range
my $a_2k = $minimum + (rand($maximum - $minimum));



# Probability Density Function of service time is:
#
#			[0				for t <= alpha_1			]
# g(t) = 	[gamma / t^beta	for alpha_1 <= t <= alpha_2	]
#			[0				for t >= alpha_2			]
#
# Where
my $alpha_1 = 0.43;
my $alpha_2 = 0.98;
my $beta = 0.86;
my $gamma = (1-$beta) / $alpha_2**(1-$beta)  -  $alpha_1**(1-$beta);
#	
# For generating random numbers with this probability distribution,
# we first need to find the Cumulative Density Function G(t). To
# do this we integrate over the curve gamma/t^beta from alpha_1 to t.
#
# This gives the CDF(t),  = G(t)
#
#			| 	 0											for t <= alpha_1
#			|	
# G(t) =	| 	t^(1-$beta) - $alpha_1 ^(1-$beta)
#			|	---------------------------------------		for alpha_1 <= t <= alpha_2
#			|	$alpha_2 ^(1-$beta) - $alpha_1 ^(1-$beta)
#			|
#			|	and 1 										for t >= alpha_2			
#
# We can see that if t = alpha_2 then the cumulative probability of
# getting a value of 0.98 or less is 100% thus it is correct.
# Now we need to inverse the function so we can find the 't-intercepts'
# from given 'u' values
#
# Therefore our values for t given u
# between 0 and 1 are 
# t = [u * ($alpha_2 ^(1-$beta) - $alpha_1 ^(1-$beta)) + $alpha_1 ^(1-$beta)]^(1/(1-$beta))
# Lets creates some constants to make our code easier to read later on.
#
my $constant_1 = $alpha_2**(1-$beta) - $alpha_1**(1-$beta);
my $constant_2 = $alpha_1**(1-$beta);



###########################################
# Initialising the events
###########################################

# Initialising the next arrival event
my $next_arrival_time = $a_1k * $a_2k;
my $service_time_nonadjusted_for_f = (((rand(1) * $constant_1) + $constant_2)**(1/(1-$beta)));
# Note here that the service time is adjusted by the frequency of the server(s)
my $service_time_next_arrival = $service_time_nonadjusted_for_f / $frequency;

# No jobs in server so next depart is in inf amount of time
my $next_departure_time = "inf";



#################################################################
# Initialising the Master clock, number_of_jobs, and jobs list
#################################################################

# jobs_in_server is a matrix with 2 columns
# jobs_in_server(k,1) (i.e. k-th row, 1st column of jobs_in_server)
# contains the arrival time of the k-th job in the server
# jobs_in_server(k,2) (i.e. k-th row, 2nd column of jobs_in_server)
# contains the service time remaining of the k-th job in the server
# The jobs_in_server 1st row has information on the 1st job in the server etc

# Initialise the master clock 
my $master_clock = 0; 
# Initialise job list

# Number of current jobs being worked on / sharing the sever
my $number_current_jobs = 0;



# Start iteration until the end time
while ($master_clock < $sim_time) {
    
    # Find out whether the next event is an arrival or departure    
    if ($next_arrival_time < $next_departure_time){
        $next_event_time = $next_arrival_time;
        $next_event_type = 1;
	} else {
        $next_event_time = $next_departure_time;
        $next_event_type = 0;
    }


    # update master clock
    $master_clock = $master_clock + $next_event_time;

	# Update all the service times of jobs in server
	foreach $time_arrived (sort keys %jobs_in_server){
		#Reduce the time remaining by the (next event time / number of jobs in server) as it is a PS server
		$jobs_in_server{$time_arrived}[1] = $jobs_in_server{$time_arrived}[1] - ($next_event_time / $number_current_jobs);
	}


    # take actions depending on the event type    
    # Arrival
    if ($next_event_type == 1) { 

    	$number_current_jobs = $number_current_jobs + 1;
        #Add new job to hash    
        $jobs_in_server{$master_clock} = [$next_arrival_time, $service_time_next_arrival, $master_clock];


        # Sum up the time till the next 'server' number of arrivals
        $sum_s_requests_later = 0;
        for ($i=0; $i < $servers; $i+=1){
        	$a_1k = (-log(1-rand(1))/$lambda);
        	$a_2k = $minimum + (rand($maximum - $minimum));
            $sum_s_requests_later = $sum_s_requests_later + ($a_1k * $a_2k);
        }

        $next_arrival_time = $sum_s_requests_later;
        $service_time_nonadjusted_for_f = (((rand(1) * $constant_1) + $constant_2)**(1/(1-$beta)));
        $service_time_next_arrival =  $service_time_nonadjusted_for_f/ $frequency;



    # Departure
    } elsif ($next_event_type == 0) {

        if ($master_clock > 5000) {
    	   $N = $N + 1;
    	   $T = $T + $master_clock - $jobs_in_server{$next_departure_key}[2];
           print "$N,",$T/$N, "\n";
        }

        # Reduce time till next arrival
        $next_arrival_time = $next_arrival_time - $next_event_time;

        # Delete departing job and reduce jobs in server by 1
    	$number_current_jobs = $number_current_jobs - 1;
    	delete $jobs_in_server{$next_departure_key};



        

    }


    $next_departure_time = "inf";
    foreach $time_arrived (sort keys %jobs_in_server){
        if (($jobs_in_server{$time_arrived}[1] * $number_current_jobs) < $next_departure_time) {
            $next_departure_time = $jobs_in_server{$time_arrived}[1] * $number_current_jobs;
            $next_departure_key = $time_arrived;
        }
    }
}
        




