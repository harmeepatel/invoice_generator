mem-trace:
	sudo dtrace -x ustackframes=100 -n 'profile-97 /execname == "ae_invoice"/ { @[ustack()] = count(); } tick-60s { exit(0); }' -o out.user_stacks

mem-svg: out.user_stacks
	../../thirdparty/FlameGraph/stackcollapse.pl out.user_stacks | ../../thirdparty/FlameGraph/flamegraph.pl > memory.svg
