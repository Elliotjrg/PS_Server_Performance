#!/usr/bin/perl -w

###########################################
# 
# THIS SCRIPT IS USED TO VARIFY THE SIM
# CODE. NOTE THE NUMBER GENERATION IS NOT
# CONSIDERED AS WE HAVE SHOWEN IT IS 
# CORRECT MATHAMETICALLY IN THE REPORT
#
###########################################



# COMP9334 Project
# PS Server Sim VARIFICATION
# 29/4/17
#
# Elliot Griffiths
# z3332776
# elliotjg@gmail.com



###########################################
# Initialising & setting parameters
###########################################

# Set the seed for pseudo-random number generation
srand(1);

# Simulation time
#my $sim_time = $ARGV[0];

# Set the number of servers running and find the frequency
my $servers = 1;
my $watts = 2000;
my $power = $watts / $servers;
my $frequency = 1.25 + 0.31*(($power/200) - 1);

# T is the cumulative response time 
my $T = 0;
# Number of completed customers at the end of the simulation
my $N = 0;



$next_arrival_time = 1;
my @request_times = (2, 3, 5);
my @request_service_times = (2.1, 3.3, 1.1, 0.5);


my $next_departure_time = "inf";



#################################################################
# Initialising the Master clock, number_of_jobs, and jobs list
#################################################################

# Initialise the master clock 
my $master_clock = 0; 
# Initialise job list

# Number of current jobs being worked on / sharing the sever
my $number_current_jobs = 0;

# Start iteration until the end time
while ($next_arrival_time ne 'inf' or $next_departure_time ne 'inf') {
    


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
        $jobs_in_server{$master_clock} = [$next_arrival_time, (shift @request_service_times), $master_clock];

        # QUEUE UP NEXT JOB
        if (@request_times) {
            $next_arrival_time = ((shift @request_times) - $master_clock);
        } else {
            $next_arrival_time = 'inf';
        }

    # Departure
    } elsif ($next_event_type == 0) {

    	$N = $N + 1;
    	$T = $T + $master_clock - $jobs_in_server{$next_departure_key}[2];


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
        


print "\n$N jobs completed by 1 server(s) at 1GHz frequency in $T time therefore mean response time is ", $T/$N, "\n\n";



