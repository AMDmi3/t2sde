# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by scripts/Create-CopyPatch.
# 
# T2 SDE: package/.../iptables/rocknet_iptables.sh
# Copyright (C) 2004 - 2020 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

ipv=""

function ipt_addcode() {
	code="$4"
	ipv6code="${code/iptables/ip6tables}"
	[ "$ipv" != "-6" ] && addcode $1 $2 $3 "$code"
	[ "$ipv" != "-4" ] && addcode $1 $2 $3 "$ipv6code"
}

iptables_init_if() {
	if isfirst "iptables_$if"; then
		ipv="" # always init ipv4/6 chains for now
		# prepare INPUT
		ipt_addcode up   1 1 "iptables -N firewall_$if"
		ipt_addcode up   1 2 "iptables -A INPUT -i $if -m state --state ESTABLISHED,RELATED -j ACCEPT"
		ipt_addcode up   1 3 "iptables -A INPUT -i $if -j firewall_$if"

		# prepare FORWARD
		ipt_addcode up   1 1 "iptables -N forward_$if"
		ipt_addcode up   1 2 "iptables -A FORWARD -i $if -m state --state ESTABLISHED,RELATED -j ACCEPT"
		ipt_addcode up   1 3 "iptables -A FORWARD -i $if -j forward_$if"

		# clean INPUT
		ipt_addcode down 1 3 "iptables -F firewall_$if"
		ipt_addcode down 1 2 "iptables -D INPUT -i $if -j firewall_$if"
		ipt_addcode down 1 2 "iptables -D INPUT -i $if -m state --state ESTABLISHED,RELATED -j ACCEPT"
		ipt_addcode down 1 1 "iptables -X firewall_$if"

		# clean FORWARD
		ipt_addcode down 1 3 "iptables -F forward_$if"
		ipt_addcode down 1 2 "iptables -D FORWARD -i $if -j forward_$if"
		ipt_addcode down 1 2 "iptables -D FORWARD -i $if -m state --state ESTABLISHED,RELATED -j ACCEPT"
		ipt_addcode down 1 1 "iptables -X forward_$if"
	fi
}

iptables_parse_conditions() {
	iptables_cond=""
	[ "$1" == "-4" -o "$1" == "-6" ] && ipv="$1" && shift
	while [ -n "$1" ]; do
		case "$1" in
		    all)
			shift
			;;
		    tcp|udp)
			iptables_cond="$iptables_cond -p $1 --dport $2"
			shift; shift
			;;
		    icmp)
			iptables_cond="$iptables_cond -p icmp --icmp-type $2"
			shift; shift
			;;
		    ip)
			iptables_cond="$iptables_cond -s $2"
			shift; shift
			;;
		    *)
			error "Unkown accept/reject/drop condition: $1"
			shift
		esac
	done
}

public_accept() {
	iptables_parse_conditions "$@"
	local level=6; [ "$ip" ] && level=5
	ipt_addcode up 1 $level "iptables -A firewall_$if ${ip:+-d $ip} $iptables_cond -j ACCEPT"
	iptables_init_if
}

public_reject() {
	iptables_parse_conditions "$@"
	local level=6; [ "$ip" ] && level=5
	ipt_addcode up 1 $level "iptables -A firewall_$if ${ip:+-d $ip} $iptables_cond -j REJECT"
	iptables_init_if
}

public_drop() {
	iptables_parse_conditions "$@"
	local level=6; [ "$ip" ] && level=5
	ipt_addcode up 1 $level "iptables -A firewall_$if ${ip:+-d $ip} $iptables_cond -j DROP"
	iptables_init_if
}

public_restrict() {
	iptables_parse_conditions "$@"
	local level=6; [ "$ip" ] && level=5
	ipt_addcode up 1 $level "iptables -A forward_$if ${ip:+-d $ip} $iptables_cond -j DROP"
	iptables_init_if
}

public_iptables() {
	[ "$1" == "-4" -o "$1" == "-6" ] && ipv="$1" && shift
	local level=6
	ipt_addcode up 1 $level "iptables $*"
	iptables_init_if
}

public_iptables_down() {
	[ "$1" == "-4" -o "$1" == "-6" ] && ipv="$1" && shift
	local level=6
	ipt_addcode down 1 $level "iptables $*"
	iptables_init_if
}

public_conduit() {
	# conduit (tcp|udp) port targetip[:targetport]
	#
	local proto=$1 port=$2
	local targetip=$3 targetport=$2

	if [ "${targetip/:/}" != "$targetip" ]; then
		targetport=${targetip#*:}
		targetip=${targetip%:*}
	fi

	addcode up 1 4 "iptables -t nat -A PREROUTING -i $if ${ip:+-d $ip} -p $proto --dport $port -j DNAT --to $targetip:$targetport"
	addcode up 1 4 "iptables -A forward_$if  -p $proto -d $targetip --dport $targetport -j ACCEPT"

	iptables_init_if
}

public_clamp_mtu() {
	addcode up 1 1 "iptables -A FORWARD ${if:+-o $if} -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu"
	addcode down 9 1 "iptables -D FORWARD ${if:+-o $if} -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu"
}

public_masquerade() {
	if [ "$ip" ]; then
		addcode up   1 6 "iptables -t nat -A POSTROUTING ${1:+-s $1} -o $if -j SNAT --to $ip"
		addcode down 9 6 "iptables -t nat -D POSTROUTING ${1:+-s $1} -o $if -j SNAT --to $ip"
	else
		addcode up   1 6 "iptables -t nat -A POSTROUTING ${1:+-s $1} -o $if -j MASQUERADE"
		addcode down 9 6 "iptables -t nat -D POSTROUTING ${1:+-s $1} -o $if -j MASQUERADE"
	fi
}
