#!/usr/bin/perl

while(<>) {
	#if (/^NET\s+\"([\S_\[\]]+)\"\s+LOC\s+=\s+\"(\S)\"\s+\|\s+IOSTANDARD\s+=\s+(\S+)\s+;/) {
	if (/^NET\s+\"([\S_\[\]]+)\"\s+LOC\s+=\s+\"(\S+)\"\s+\|\s+IOSTANDARD\s+=\s+(\S+)\s+;/) {
		print "set_property PACKAGE_PIN $2 [get_ports $1]\n";
		print "set_property IOSTANDARD $3 [get_ports $1]\n";
	}
}
