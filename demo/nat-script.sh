# Nat instance
# second network interface with EIP attached

iptables -F -t nat
#iptables -A POSTROUTING -t nat -o eth1 -p tcp --sport 5000:5100 -j SNAT --to 10.0.0.100:7000-7100
iptables -t nat -A POSTROUTING  -j MASQUERADE

iptables -F -t mangle
iptables -t mangle -N MARK-PROD
iptables -t mangle -A MARK-PROD -p tcp --sport 5000:5100 -j MARK --set-mark 1
iptables -t mangle -A MARK-PROD -j CONNMARK --save-mark
#iptables -t mangle -A PREROUTING -i eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j CONNMARK --restore-mark
iptables -t mangle -A PREROUTING -i eth0 -j MARK-PROD

#iptables -A OUTPUT -t mangle  -p tcp  --sport 5000:5100 -j MARK --set-mark 1
#iptables -A OUTPUT -t mangle  -j CONNMARK --restore-mark

for f in /proc/sys/net/ipv4/conf/*/rp_filter; do echo 0 > $f; done
echo 1 > /proc/sys/net/ipv4/route/flush


echo 250 PROD >> /etc/iproute2/rt_tables
ip route flush table PROD
ip route add table PROD default via 10.0.0.1 dev eth1
ip route add table PROD 10.0.0.0/24 dev eth0  proto kernel  scope link  src 10.0.0.7
ip route add table PROD 169.254.169.254 dev eth0
ip route show table PROD

ip rule del from all fwmark 1 2>/dev/null
ip rule add fwmark 1 table PROD
ip route flush cache

#http://backreference.org/2012/10/07/policy-routing-multihoming-and-all-that-jazz/

# modprobe iptable_nat
# modprobe ip_conntrack
# echo "1" > /proc/sys/net/ipv4/ip_forward
