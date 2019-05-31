# MOTD subsystem

* `motd-create` rebuilds `/etc/motd`
* `motd-add` appends administrators messages to MOTD, if not parameter passed then clears the queue;
  `motd-create` must used after new message to update MOTD.
* `motd-daily-update` used in cron or `rc.local` to refresh MOTD; admins messages are not cleared.

## install

```
DIR=/somewhere/admin-only/directory
cp -r motd $DIR
cd $DIR/motd
./install.sh
```

## rc.local

```
# MOTD
script=/usr/local/sbin/motd-create
[ -x $script ] && $script
```