#from my bashrc
# set an ad-hoc GUI timer
timer() {
    local N=$1; shift

      (sleep $N && notify-send Bang) &
        echo "timer set for $N"
     }
timer $1 
#      $ timer 35m get the laundry
#      works great.
