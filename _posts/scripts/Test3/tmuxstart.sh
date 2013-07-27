#!/bin/sh
tmux start-server # Запуск сервера tmux
tmux new-session -n mcabber -s mcabber_ses 'mcabber' # создание сессии: -n имя окна, -s имя сессии, и после - запускаемая команда (mcabber)
tmux new-window -n vim -t mcabber_ses:2 'vim' # Создание окна под номером 2 в сессии mcabber_ses, именем vim, и запуском vim соответственно
tmux select-window -t mcabber_ses:1 # Выбор первого окна
tmux attach -t mcabber_ses # Присоединение сессии к активному терминалу

