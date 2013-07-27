#!/bin/sh 
tmux new-session -d 'vim'
tmux split-window -h 'mc'

#tmux split-window -h 
tmux new-window 2: 'ncdu'
tmux new-window 'bash'
#new -d
#neww
#neww

tmux new-window 3: 'term'
tmux new-window 'csh'
tmux split-window -h 'sh'

tmux -2 attach-session -d 
