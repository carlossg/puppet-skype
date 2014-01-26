#!/bin/bash
#
# Init file for daemonized Skype service
#
### BEGIN INIT INFO
# Provides:          skype
# Required-Start:    $local_fs $remote_fs $network
# Required-Stop:     $local_fs $remote_fs $network
# Default-Start:     3 4 5
# Default-Stop:      0 1 2 6
# X-Interactive:     false
# Short-Description: Start/stop daemonized Skype service
### END INIT INFO
#
# chkconfig: 345 80 10
#
# processname: skype
#
# pidfile: /var/run/skype.pid
#

if [ -r /etc/rc.d/init.d/functions ]; then
    . /etc/rc.d/init.d/functions
    log_daemon_msg() {
        msg=$1
        prog=$2
        echo -n $"$msg $DESC: "
    }
    log_end_msg() {
        if [ "$1" = "0" ]; then
            success
        elif [ "$1" = "1" ]; then
            failure
        fi
        echo
    }

elif [ -r /lib/lsb/init-functions ]; then
    . /lib/lsb/init-functions
else
    echo "Could not find a helper script needed to run this script."
    exit 1
fi

DESC="Skype daemon"
DAEMON_USER=skype
PROGNAME=`basename $0`
PIDFILE=/var/run/skype.pid
XSERVERNUM=20
XAUTHFILE=/home/skype/.Xauthority
LOGFILE=/var/log/skype.log
DBPATH=/home/skype/.Skype
XAUTHPROTO=.
SKYPE=/usr/bin/skype

if [ -r /etc/default/skype ]; then
  . /etc/default/skype
fi
[ -f /etc/sysconfig/skype ] && . /etc/sysconfig/skype

RETVAL=0

dircheck() {
    if [ ! -d `dirname "$1"` ]; then
        echo "`dirname \"$1\"` does not exist"
        return 1
    else
        return 0
    fi
}

start() {
    log_daemon_msg "Starting" $DESC
    if ! dircheck "$LOGFILE" || ! dircheck "$XAUTHFILE"; then
        log_end_msg 1
        echo
        RETVAL=1
        return 
    fi
    if [ ! -f $LOGFILE ] ; then
        touch $LOGFILE
        chown $DAEMON_USER: $LOGFILE
    fi

    MCOOKIE=`mcookie` && \
    sudo -H -u "$DAEMON_USER" env XAUTHORITY=$XAUTHFILE sh -c "xauth add \":$XSERVERNUM\" \"$XAUTHPROTO\" \"$MCOOKIE\" >> \"$LOGFILE\" 2>&1" && \
    sudo -H -u "$DAEMON_USER" sh -c "Xvfb :$XSERVERNUM -auth $XAUTHFILE -screen 0 800x600x8 -nolisten tcp >> \"$LOGFILE\" 2>&1 & echo \$!" >"$PIDFILE" &&
    sleep 3 && \
    (sudo -H -u "$DAEMON_USER" env DISPLAY=:$XSERVERNUM XAUTHORITY=$XAUTHFILE SKYPE="$SKYPE" sh -c "nohup \"$SKYPE\" --dbpath=\"$DBPATH\" &") >> "$LOGFILE" 2>&1 && \
    (log_end_msg 0 && [ -d /var/lock/subsys ] && touch /var/lock/subsys/skype || true) \
        || (RETVAL=$?; kill -TERM `cat $PIDFILE`; log_end_msg 1)
}

stop() {
    log_daemon_msg "Stopping" $DESC
    if [ -e "$PIDFILE" ]; then
        kill -TERM `cat $PIDFILE` && \
        rm -f $PIDFILE && \
        if [ -d /var/lock/subsys ]; then rm -f /var/lock/subsys/skype; fi && \
        log_end_msg 0 || log_end_msg 1
    else
        log_end_msg 1
        RETVAL=1
    fi
}

status() {
    start-stop-daemon --status --pidfile $PIDFILE
    RETVAL=$?

    if [ "$RETVAL" != "0" ]; then
        log_success_msg "$DESC is not running."
    else
        log_success_msg "$DESC is running with pid `cat $PIDFILE`"
    fi
}

usage() {
    echo "Usage: $PROGNAME {start|stop|status|restart}"
}

case $1 in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    status)
        status
        ;;

    *)
        usage
        RETVAL=255
        ;;
esac

exit $RETVAL
