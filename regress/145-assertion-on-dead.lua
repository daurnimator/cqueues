#!/bin/sh
_=[[
	. "${0%%/*}/regress.sh"
	exec runlua "$0" "$@"
]]
require"regress".export".*"

local co = coroutine.create(function()
	coroutine.yield()
end)
coroutine.resume(co) -- kick off coroutine
coroutine.resume(co) -- resume a yield with no arguments

local status = coroutine.status(co)
check(status == "dead", "expected dead coroutine (got %q)", status)

local cq = require"cqueues".new()
cq:attach(co)
cq:step() -- previously would trigger C assert and abort process

say"OK"
