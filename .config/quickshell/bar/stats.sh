#!/bin/sh
# Prints "<cpu%> <mem%> <max temp °C>".
read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ </proc/stat
sleep 0.4
read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ </proc/stat
busy=$(( (u2 + n2 + s2 + q2 + sq2 + st2) - (u1 + n1 + s1 + q1 + sq1 + st1) ))
idle=$(( (i2 + w2) - (i1 + w1) ))
total=$(( busy + idle ))
cpu=$(( total > 0 ? 100 * busy / total : 0 ))

mem=$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf "%d", 100 * (t - a) / t}' /proc/meminfo)

temp=0
for zone in /sys/class/thermal/thermal_zone*/temp; do
	[ -r "$zone" ] || continue
	t=$(( $(cat "$zone") / 1000 ))
	[ "$t" -gt "$temp" ] && temp=$t
done

echo "$cpu $mem $temp"
