---
author:
- William Ahern
title: ' The <span>`cqueues` </span>User Guide '
...

for composing\

Socket, Signal, Thread, & File Change Messaging\

on\

Linux, OS X, Solaris,\
FreeBSD, NetBSD, & OpenBSD

with\

<span>![image](art/lua.pdf)</span>

Dependencies
============

Operating Systems
-----------------

<span>`cqueues` </span>heavily relies on a modern POSIX environment. But
the fundamental premise is to build on the new but non-standard polling
facilities provided by contemporary Unix environments. Specifically, BSD
<span>`kqueue` </span>, Linux <span>`epoll` </span>, and Solaris Event
Ports.

<span>`cqueues` </span>should work on recent versions of Linux, OS X,
Solaris, NetBSD, FreeBSD, OpenBSD, and derivatives. The only other
possible candidate is AIX, if and when support for AIX’s <span>`pollset`
</span> interface is added to the embedded “kpoll” library.

### $\lnot$ Microsoft Windows

Microsoft Windows support is basically out of the question[^1], for far
too many reasons to put here. Aside from the more technical reasons,
Windows I/O and networking programming interfaces have a fundamentally
different character than on Unix. Unix historically relies on readiness
polling, while Windows uses event completion callbacks. There are
strengths and weaknesses to each approach. Trying to paper over the
chasm between the two approaches invariably results in a framework with
the strengths of neither and the weaknesses of both. The purpose of
<span>`cqueues` </span>is to leverage the strengths of polling as well
as address the weaknesses.

Libraries
---------

### LuaJIT, Lua 5.2, Lua 5.3

<span>`cqueues` </span>principally targets Lua 5.2 and above. It’s not
fully portable to Lua 5.1 because <span>`cqueues` </span>relies on
ephemeron tables to prevent coroutine/controller reference cycles, and
because Lua 5.1 does not support yielding from metamethods and
iterators. LuaJIT removes the latter of these handicaps, and so
<span>`cqueues` </span>targets LuaJIT secondarily. In lieu of ephemeron
tables, application code must be sure not to hold a reference to a
parent controller in an upvalue of the coroutine. Instead, use
<span>`cqueues.running` </span>.

### OpenSSL

The <span>`cqueues` </span><span>`socket` </span> module provides
seamless SSL/TLS support using OpenSSL.

Comprehensive bindings for certificate and key management are provided
in the [companion <span>`openssl` </span> module,
`luaossl`](http://25thandClement.com/~william/projects/luaossl.html).

### pthreads

<span>`cqueues` </span>provides an optional threading module, using
POSIX threads.[^2] Internally it consistently uses thread-safe routines
when built with either the \_REENTRANT or \_THREAD\_SAFE feature macros,
such as <span>`pthread_sigmask` </span> instead of <span>`sigprocmask`
</span>. Thread support is enabled by default.

##### Linking

Note that on some systems, such as NetBSD and FreeBSD, the loading
application must be linked against pthreads (using -lpthread
or -pthread). It is not enough for the <span>`cqueues` </span>module to
pull in the dependency at load time. In particular, if using the stock
Lua interpreter, it must have been linked against pthreads at build
time. Add the appropriate linker flag to MYLIBS in
lua-5.2.x/src/Makefile.

##### OpenBSD

OpenBSD 5.1 threading is completely *fubar*, especially with regard to
signals, because of OpenBSD’s transition to kernel threading. If using
OpenBSD, be sure to compile *without* the thread-safe macros predefined,
especially if using <span>`cqueues.signal` </span>.

Compilers
---------

The source code is mostly ISO C99 compliant, and even more so with
regards to ISO C11. But regardless of standards conformance, it aims to
build cleanly with the native compiler for each targeted platform. It
currently builds with recent versions of GCC, clang, and SunPro.

Patches are welcome to silence compiler diagnostics.

GNU Make
--------

The Makefile requires GNU Make, usually installed as gmake on platforms
other than Linux or OS X. The actual `Makefile` proxies to
`GNUmakefile`. As long as `gmake` is installed on non-GNU systems you
can invoke your system’s `make`.

Installation
============

All the C modules are built into a single core C library. The core
routines are then wrapped and extended through Lua modules. Because
there several extant versions of Lua often used in parallel on the same
system, there are individual targets to build and install for each
supported Lua version. The targets `all` and `install` will attempt to
build and install both Lua 5.1 and 5.2 modules.

Note that building and installation and can accomplished in a single
step by simply invoking one of the install targets with all the
necessary variables defined.

Building
--------

There is no separate `./configure` step. System introspection occurs
during compile-time. However, the “`configure`” make target can be used
to cache the build environment so one needn’t continually use a long
command-line invocation.

All the common GNU-style compiler variables are supported, including
`CC`, `CPPFLAGS`, `CFLAGS`, `LDFLAGS`, and `SOFLAGS`. Note that you can
specify the path to Lua 5.1, Lua 5.2, and Lua 5.3 include headers at the
same time in CPPFLAGS; the build system will work things out to ensure
the correct headers are loaded when compiling each version of the
module.

### Targets

`all`

:   \
    Build modules for Lua 5.1 and 5.2.

`all5.1`

:   \
    Build Lua 5.1 module.

`all5.2`

:   \
    Build Lua 5.2 module.

`all5.3`

:   \
    Build Lua 5.3 module.

Installing
----------

All the common GNU-style installation path variables are supported,
including `prefix`, `bindir`, `libdir`, `datadir`, `includedir`, and
`DESTDIR`. These additional path variables are also allowed:

`lua51path`

:   \
    Install path for Lua 5.1 modules, e.g. `$(prefix)/share/lua/5.1`

`lua51cpath`

:   \
    Install path for Lua 5.1 C modules, e.g. `$(prefix)/lib/lua/5.1`

`lua52path`

:   \
    Install path for Lua 5.2 modules, e.g. `$(prefix)/share/lua/5.2`

`lua52cpath`

:   \
    Install path for Lua 5.2 C modules, e.g. `$(prefix)/lib/lua/5.2`

`lua53path`

:   \
    Install path for Lua 5.3 modules, e.g. `$(prefix)/share/lua/5.3`

`lua53cpath`

:   \
    Install path for Lua 5.3 C modules, e.g. `$(prefix)/lib/lua/5.3`

### Targets

`install`

:   \
    Install modules for Lua 5.1 and 5.2.

`install5.1`

:   \
    Install Lua 5.1 module.

`install5.2`

:   \
    Install Lua 5.2 module.

`install5.3`

:   \
    Install Lua 5.3 module.

Usage
=====

Conventions
-----------

### Polling

<span>`cqueues` </span>works through a simple protocol. When a coroutine
yields to its parent <span>`cqueues` </span>controller, it can pass one
or more objects. These objects are introspected for three methods:
<span>`:pollfd` </span>, <span>`:events` </span>, and <span>`:timeout`
</span>. These methods generate the parameters for installing descriptor
and timeout events. When one of these events fires, <span>`cqueues`
</span>will resume the coroutine, passing the relevant objects which
were interested in the triggered event. It’s analogous to calling Unix
<span>`poll` </span>, and in fact the routine <span>`cqueues.poll`
</span> is provided as a wrapper for <span>`coroutine.yield`
</span>.[^3]

#### <span>`:pollfd()` </span>

The <span>`:pollfd` </span> method should return a descriptor integer or
nil. This descriptor must remain in existence until the owner object is
garbage collected, <span>`cqueues.cancel` </span> is used, the coroutine
executes one additional yield/resume cycle (so the old descriptor is
expired from the descriptor queue), or until after the coroutine exits.
If the descriptor is closed prematurely, the kernel will remove it from
the internal descriptor queue, bringing it out of sync with the
controller, and probably causing <span>`cqueues:step` </span> to return
EBADF or ENOENT errors.

Alternatively, <span>`:pollfd` </span> may return a condition variable
object, or the member field may itself be a condition variable instead
of a function. This permits user code to create *ad hoc* pollable
objects.

#### <span>`:events()` </span>

The <span>`:events` </span> method should return a string or nil.
<span>`cqueues` </span>searches the string for the flags ‘r’ and ‘w’,
which describe the events to associate with the descriptor—respectively,
POLLIN and POLLOUT.

#### <span>`:timeout()` </span>

The <span>`:timeout` </span> should return a number or nil. This
schedules an independent timeout event. To effect a simple one second
timeout, you can do

``` {language="lua"}
        cqueues.poll({ timeout = function() return 1.0 end })
```

which is equivalent to the shortcut

``` {language="lua"}
    cqueues.poll(1.0)
```

Instantiated <span>`cqueues` </span>objects implement all three
methods.[^4] In particular, this means that you can stack
<span>`cqueues` </span>, or poll on a <span>`cqueues` </span>object
using some other event loop library. Each <span>`cqueues` </span>object
is entirely self-contained, without any global state.

### $\lnot$ Globals

Like the core controller module, other <span>`cqueues` </span>modules
adhere to a *no global side effects* discipline. In particular, this
means

-   no global process variables;

-   no signal handling gimmicks—like the pipe trick—which could conflict
    with other components of your application[^5];

-   consistent use of thread-safe function variants; and

-   consistent use of O\_CLOEXEC and similar flags to eliminate or
    reduce <span>`fork` </span> $+$ <span>`exec` </span> races in
    threaded applications.

### Errors

The usual behavior is for errors to be returned directly. But see
<span>`socket.onerror` </span>. If a routine is specified to return an
object or string, nil is returned; if a boolean, false is returned. In
both cases, these are usually followed by a numeric error code. Thus, if
a routine is specified to return two values on success, then on error
three values are returned, the first two nil or false, and the third an
error code.

<span>`cqueues` </span>is a relatively low-level component library. In
almost all cases errors will be system errors, returned as numeric error
codes for easy and efficient comparison. For example, attempting to
create a UNIX domain socket with <span>`socket.listen` </span> in a
directory without sufficient permissions might return ‘nil,
<span>`EACCES` </span>’.

#### `EAGAIN`

<span>`cqueues` </span>modules are implemented in both C and Lua. The C
routines never yield, and always return recoverable errors directly.
Most C routines are wrapped—and methods interposed—with Lua functions.
These Lua functions usually poll when <span>`EAGAIN` </span> is
encountered and retry the C routine on resumption. Few methods will
return <span>`EAGAIN` </span> directly.

#### `ETIMEDOUT`

This error value is usually seen when a timeout is specified by the
caller of a logically synchronous method. The method will normally yield
and poll if the operation cannot be completed immediately, but if the
timeout expires then it will return a failure with <span>`ETIMEDOUT`
</span>.

#### `EPIPE`

In Unix <span>`EPIPE` </span> is only encountered when attempting to
write to a closed pipe or socket. In <span>`cqueues`
</span><span>`EPIPE` </span> is used to signal both EOF and a closed
output stream.[^6] The low-level I/O method <span>`socket:recv` </span>,
for example, returns <span>`EPIPE` </span> on EOF. In other cases, as
with <span>`socket:read` </span>, EOF is not an error condition.

#### `EBADF`

This error commonly occurs in asynchronous applications, which are
especially prone to bugs related to their complex state management. With
Lua code using the <span>`cqueues` </span>APIs, <span>`EBADF` </span>
should never be encountered. When it does occur, it’s a sure sign of a
bug somewhere in the parent application or an extension module
and—hopefully—not <span>`cqueues` </span>.

#### The Future

The idiomatic protocol for returning errors in Lua is a string
representation followed by the integer errno number. This is how Lua’s
<span>`io` </span> and <span>`file` </span> modules behave. The original
concern was that this would be too wasteful for a networking library,
where “errors” like EAGAIN, ETIMEDOUT, and EPIPE are common and not very
exceptional. Copying even small strings into the Lua VM is somewhat
costly. However, in the future the API may be configurable to use the
Lua-idiomatic protocol by default, using upvalue memoization to minimize
the cost of returning string representations.

In the meantime, the auxiliary routines <span>`auxlib.assert` </span>
and <span>`auxlib.fileresult` </span> can be used to explicitly achieve
the idiomatic behavior.

Modules
-------

<span><span>`cqueues` </span></span>

#### <span>`cqueues.VENDOR` </span>

String describing the vendor, e.g. william@25thandClement.com. If you
fork this project please change this string so I don’t receive
unwarranted scorn or praise.

#### <span>`cqueues.VERSION` </span>

Number describing the running version, formatted as YYYYMMDD. Official
releases are tagged in the git repo as rel-YYYYMMDD.

#### <span>`cqueues.COMMIT` </span>

Git commit hash string of HEAD.

#### <span>`cqueues.type(obj)` </span>

Return the string “controller” if $obj$ is a controller object, or $nil$
otherwise.

#### <span>`cqueues.interpose(name, function)` </span>

Add or interpose a <span>`cqueues` </span>controller class method.
Returns the previous method, if any.

#### <span>`cqueues.monotime()` </span>

Return the system’s monotonic clock time, usually
clock\_gettime(CLOCK\_MONOTONIC).

#### <span>`cqueues.cancel(fd)` </span>

Cancels the specified descriptor for all controllers. This ensures safe
early closure of descriptors. However, the complexity is approximately M
2 log N, where M is the number of controllers, and N the number of
descriptors per controller (presuming equal distribution). For most
purposes this is entirely inconsequential. By contrast, however,
implicit cancellation through GC or yield/resume cycling is O(1).

Any coroutine polling on the canceled descriptor is placed on its
controller’s pending queue.

#### <span>`cqueues.poll(\ldots)` </span>

Takes a series of objects obeying the polling protocol and yields
control to the parent <span>`cqueues` </span>controller. On an event
resumes the coroutine, passing the objects which triggered resumption. A
number value is interpreted as a timeout.

#### <span>`cqueues.sleep(number)` </span>

Yields to the parent <span>`cqueues` </span>controller and schedules a
wakeup for ‘number’ seconds in the future.

#### <span>`cqueues.running()` </span>

Returns two values: the immediate controller currently executing, if
any, or nil; and a boolean—true if the caller’s coroutine is the same
coroutine resumed by the controller.

#### <span>`cqueues.resume(co)` </span>

See <span>`auxlib.resume` </span>.

#### <span>`cqueues.wrap(f)` </span>

See <span>`auxlib.wrap` </span>.

#### <span>`cqueues.new()` </span>

Create a new cqueues object.

#### <span>`cqueue:attach(coroutine)` </span>

Attach and manage the specified coroutine. Returns the controller.

#### <span>`cqueue:wrap(function)` </span>

Execute function inside a new coroutine managed by the controller.
Returns the controller.

#### <span>`cqueue:step([timeout])` </span>

Step once through the event queue. Unless the timeout is explicitly
specified as `0`, or unless the current thread of execution is a
<span>`cqueues` </span>managed coroutine, *it suspends the process
indefinitely or for the specified timeout* until a descriptor event or
timeout fires.

Returns true or false. If false—i.e. a coroutine exited abnormally—then
a second return value holds the error message. :step can be called again
after errors.

If embedding <span>`cqueues` </span>within an existing application, the
top-level :step invocation should always specify a 0 timeout. A
controller is a pollable object, and the descriptor returned by the
:pollfd method can be used with third-party event libraries, whether
written in Lua, C, or some other language. Don’t forget to also schedule
a timeout using the value from :timeout.

#### <span>`cqueue:loop([timeout])` </span>

Invoke <span>`cqueues:step` </span> in a loop, exiting on error,
timeout, or if the event queue is empty. Returns true if no error
occurred, or false and an error string from <span>`cqueues:step`
</span>.

#### <span>`cqueue:errors([timeout])` </span>

Returns an iterator function over errors returned from
<span>`cqueues:loop` </span>. If <span>`cqueues:loop` </span> returns
successfully because of an empty event queue, or if the timeout expires,
returns nothing, which terminates any for-loop. ‘timeout’ is cumulative
over the entire iteration, not simply passed as-is to each invocation of
<span>`cqueues:loop` </span>.

#### <span>`cqueue:empty()` </span>

Returns true if there are no more descriptor or timeout events queued,
false otherwise.

#### <span>`cqueue:count()` </span>

Returns a count of managed coroutines.

#### <span>`cqueue:cancel(fd)` </span>

Cancel the specified descriptor for that controller. See cqueues.cancel.

#### <span>`cqueue:pause(signal [, signal \ldots ])` </span>

A wrapper around <span>`pselect` </span> which *suspends execution of
the process* until the controller polls ready or a signal is delivered.
This interface is provided as a very basic least common denominator for
simple slave process controller loops and similar scenarios, where
immediate response to signal delivery is required on platforms like
Solaris without a proper signal polling primitive.
(<span>`signal.listen` </span> on Solaris merely periodically queries
the pending set.)

Much better alternatives are possible for Solaris, but require global
process state or an LWP thread helper.

<span>cqueues.socket</span>

The socket bindings provide built-in DNS, SSL/TLS, buffering, and line
translation. DNS happens transparently, and SSL/TLS can be initiated
with the <span>`socket:starttls` </span> method.

The default I/O mode is “tl”—text translation and line buffering. This
makes sockets work intuitively with the most common protocols on the
Internet, like SMTP and HTTP, which require CRLF and use line delimited
framing.

#### <span>`socket[]` </span>

A table mapping socket related system identifier names to number codes,
including AF\_UNSPEC, AF\_INET, AF\_INET6, AF\_UNIX, SOCK\_STREAM, and
SOCK\_DGRAM.

#### <span>`socket.type(obj)` </span>

Return the string “socket” if $obj$ is a socket object, or $nil$
otherwise.

#### <span>`socket.interpose(name, function)` </span>

Add or interpose a socket class method. Returns the previous method, if
any.

#### <span>`socket.connect(host, port [, family] [, type])` </span>

Return a new socket immediately ready for reading or writing. DNS lookup
and TCP connection handling are handled transparently.

#### <span>`socket.connect{ \ldots }` </span>

Like <span>`socket.connect` </span> with list arguments, but takes a
table of named arguments:

<span>r | c | p<span>4.5in</span></span> field & type:default &
description\
.host & string:nil & IP address or host domain name\

.port & string:nil & host port\

.path & string:nil & UNIX domain socket path\

.family & number & protocol family—AF\_INET (default), AF\_INET6,
AF\_UNIX (default if .path specified)\

.type & number & protocol type—SOCK\_STREAM (default) or SOCK\_DGRAM\

.mode & string:nil & fchmod or chmod socket after creating UNIX domain
socket\

.mask & string:nil & set and restore umask when binding UNIX domain
sockets\

.unlink & boolean:false & unlink socket path before binding\

.reuseaddr & boolean:true & SO\_REUSEADDR socket option\

.reuseport & boolean:false & SO\_REUSEPORT socket option\

.nodelay & boolean:false & TCP\_NODELAY IP option\

.nopush & boolean:false & TCP\_NOPUSH, TCP\_CORK, or equivalent IP
option\

.v6only & boolean:nil & enables or disables IPV6\_V6ONLY IPv6 option,
otherwise the system default is left as-is\

.nonblock & boolean:true & O\_NONBLOCK descriptor flag\

.cloexec & boolean:true & O\_CLOEXEC descriptor flag\

.nosigpipe & boolean:true & O\_NOSIGPIPE, SO\_NOSIGPIPE, MSG\_NOSIGNAL,
or equivalent descriptor flag\

.verify & boolean:false & require SSL certificate verification\

.sendname & boolean:true & send connect host as TLS SNI host name\
& string:nil & send specified string as TLS SNI host name\

.time & boolean:true & track elapsed time for statistics\

#### <span>`socket.listen(host, port)` </span>

Return a new socket immediately ready for accepting connections.

#### <span>`socket.listen{ \ldots }` </span>

Like <span>`socket.listen` </span> with list arguments, but takes a
table of named arguments. See also <span>`socket.connect{}` </span>.

#### <span>`socket.pair([type])` </span>

Returns two bound sockets. Type should be the system type number, e.g.
<span>`socket.SOCK_STREAM` </span> or <span>`socket.SOCK_DGRAM` </span>.

#### <span>`socket.setvbuf(mode [, size])` </span>

Set the default output buffering mode for all new sockets. See
<span>`socket:setvbuf` </span>.

#### <span>`socket.setmode([input] [, output])` </span>

Set the default I/O modes for all new sockets. See
<span>`socket:setmode` </span>.

#### <span>`socket.setbufsiz([input] [, output])` </span>

Set the default I/O buffer sizes for all new sockets. See
<span>`socket:setbufsiz` </span>.

#### <span>`socket.setmaxline([input] [, output])` </span>

Set the default I/O line-buffering limits for all new sockets. See
<span>`socket:setmaxline` </span>.

#### <span>`socket.settimeout([timeout])` </span>

Set the default timeout for all new sockets. See
<span>`socket:settimeout` </span>.

#### <span>`socket.setmaxerrs([which,][limit])` </span>

Set the default error limit for all new sockets. See
<span>`socket:setmaxerrs` </span>.

#### <span>`socket.onerror([function])` </span>

Set the default error handler for all new sockets. See
<span>`socket:onerror` </span>.

#### <span>`socket:connect([timeout])` </span>

Wait for connection establishment to succeed. You do not need to wait
before proceeding to perform read or write calls, but waiting may ease
diagnosing connection problems in your code and allows you to separate
connect phase from I/O phase timeouts.

#### <span>`socket:listen([timeout])` </span>

Wait for socket binding to succeed. You do not need to wait before
proceeding to call <span>`:accept` </span>, but waiting may ease
diagnosing binding problems in your code and allows you to separate
listen phase from accept phase timeouts.

Socket binding may not occur immediately if you provided a host address
that required DNS resolution over the network. This is uncommon for
listening sockets but supported nonetheless; the symmetry simplifies
internal code. Also, socket object instantiation with
<span>`socket.listen` </span> and <span>`socket.connect` </span> only
return errors regarding user data object construction; address lookup
and binding errors are detected later, when initiated by subsequent
method calls.

#### <span>`socket:accept([timeout])` </span>

Wait for and return an incoming client socket on a listening object.

#### <span>`socket:clients([timeout])` </span>

Iterator over <span>`socket:accept` </span>:
`for con in srv:clients() do ... end`.

#### <span>`socket:starttls([context][, timeout])` </span>

Place socket into TLS mode, optionally using the
<span>`openssl.ssl.context` </span> object as the configuration
prototype, and wait for the handshake to complete.[^7] Returns true on
success, false and an error code on failure.

#### <span>`socket:checktls()` </span>

If in TLS mode, returns an <span>`openssl.ssl` </span> object, otherwise
nil. If the openssl module cannot be loaded, returns nil and an error
string.

#### <span>`socket:setvbuf(mode [, size])` </span>

Same as Lua <span>`file:setvbuf` </span>. Analogous to “n”, “l”, and “f”
mode flags. Returns the previous output mode and output buffer size.

#### <span>`socket:setmode([input] [, output])` </span>

Sets the the input and output buffering and translation modes. Either
mode can be nil or none, in which case the mode is left unchanged.

A mode is specified as a string containing one or more of the following
flags

<span>c | p<span>6in</span></span> flag & description\
t & text mode; input or output undergoes LF/CRLF translation\
b & binary mode; no LF/CRLF translation\
n & no output buffering\
l & line buffered output\
f & fully buffered output\

Returns the previous input and output modes as fixed-sized strings. At
present the first character is one of “t” or “b”, and the second
character one of “n”, “l”, “f”, or “-” (for in the input mode).

#### <span>`socket:setbufsiz([input] [, output])` </span>

Sets the input and output buffer size. Either size can be nil or none,
in which case the size is left unchanged.

These are not hard limits for SOCK\_STREAM sockets. The input buffer
argument simply sets a minimum for input buffering, to reduce syscalls.
The output buffer argument is the same as provided to <span>`:setvbuf`
</span>, and effectively changes when flushing occurs for full- or
line-buffered output modes.

For SOCK\_DGRAM sockets, the input buffer sets a hard limit on the size
of datagram messages. Any message over this size will be truncated,
unless a previous block- or line-buffered read operation forced the
buffer to be reallocated to a larger size.

Returns the previous input and output buffer sizes, or throws an error
if the buffers could not be reallocated.

#### <span>`socket:setmaxline([input] [, output])` </span>

Sets the maximum input and output length for line-buffered operations.
Either size can be nil or none, in which case the size is left
unchanged.

These are hard limits. For line-buffered input operations, if a
<span>$\backslash$n </span>character is not found within this limit then
the data is processed as-if EOF was reached at this boundary. For
line-buffered output, a chunk is always flushed at this boundary.

Returns the previous input and output sizes.

#### <span>`socket:settimeout([timeout])` </span>

Sets the default timeout period for I/O. If nil or none, then clears any
default timeout. If a timeout is cleared, any operation which polls will
wait indefinitely until completion or an error occurs.

Sockets are instantiated without a default timeout.

#### <span>`socket:setmaxerrs([which,] limit)` </span>

Set the maximum number of times an error will be returned to a caller
before throwing an error, instead. $which$ specifies which I/O channel
limit to set—“r” for the input channel, “w” for the output channel, or
“rw” for both. $which$ defaults to “rw”. $limit$ is an integer limit.
The initial $limit$ is 100.

Returns the previous channel limits in the order specified.

Note that <span>`socket:clearerr` </span> will clear the error counters
as well as any errors.

##### Unchecked error loops

The default error handler will throw on most errors. However, EPIPE and
ETIMEDOUT are returned directly as they’re common errors that normally
need to be handled explicitly in correct applications. Furthermore,
errors will be repeated until cleared. If errors were not repeated then
unchecked transient errors could lead to difficult to detect loss of
data bugs by giving the illusion of successful forward progress.[^8]
Code which loops and fails to check the success of I/O calls could enter
an infinite loop which never yields to the controller and stalls the
process. This is a fail-safe mechanism to catch such code.

#### <span>`socket:onerror([function])` </span>

Set the error handler. The error handler is passed four arguments:
socket object, method name, error number, and stack level of caller. The
handler is expected to either throw an error or return an error code—to
be returned to the caller as part of the documented return interface.

The default error handler returns <span>`EPIPE` </span> and
<span>`ETIMEDOUT` </span> directly, and throws everything else.
<span>`EAGAIN` </span> is handled internally for logically synchronous
calls.

Returns the previous error handler, if any.

#### <span>`socket:error([which])` </span>

Returns the saved error conditions for the input and output channels.
$which$ is a string containing one or more of the characters ‘r’ and
‘w’, which return the input and output channel errors respectively and
in the order specified. $which$ defaults to the string “rw”.

#### <span>`socket:clearerr([which])` </span>

Clears the error conditions and counters for the specified I/O channels
and returns any previous errors. $which$ is a string containing one or
more of the characters “r” and “w”, which clears the input and output
channel errors respectively, and returns the previous error numbers (or
nil) in the order specified. $which$ defaults to the string “rw”.

#### <span>`socket:read(...)` </span>

Similar to Lua’s <span>`file:read` </span>, with additional formats.

            format           description
  -------------------------- -----------------------------------------------------------------------
       <span>\*n</span>      unsupported
       <span>\*a</span>      read until EOF
       <span>\*l</span>      read the next line, trimming the EOL marker
       <span>\*L</span>      read the next line, keeping the EOL marker
       <span>\*h</span>      read and unfold MIME compliant header
       <span>\*H</span>      read MIME compliant header, keeping EOL markers
   <span>`–`$marker$</span>  read multipart MIME entity chunk delineated by MIME boundary $marker$
           $number$          read $number$ bytes or until EOF
          $-number$          read 1 to $number$ bytes, immediately returning if possible

For SOCK\_DGRAM sockets, each message is treated as-if EOF was reached.
The slurp operation returns a single datagram, and line-buffered
operations will return the remaining text in a message even without a
terminating <span>$\backslash$n </span>. Datagrams will be truncated if
the message is larger than the input buffer size.

The MIME entity reader allows efficient reading of large MIME-encoded
bodies, such as with HTTP POST file uploads. The format will return
chunks until the boundary is reached. The last chunk will have any
trailing EOL marker removed, regardless of input mode, as this is part
of the boundary token. In binary mode chunks are sized according to the
current input channel buffer size, except that the last chunk will
probably be short. In text mode chunks will not exceed the maximum of
the current input channel buffer size or maximum line size; and in
addition to EOL translation, chunks are broken along line boundaries
with multiple lines aggregated into a single chunk.

Both the MIME header and MIME entity reader require a proper terminating
condition. In particular, *EOF is not a terminating condition*.
Applications must be careful to handle truncation if the stream was
prematurely closed. When looping over one of these input formats, the
application should read the next line of input after the loop
terminates. If the next next line does not match the terminating
condition, then the stream is invalid and the application should abort
processing the stream.

For MIME headers the next line should be non-$nil$ and should not appear
to be a prefix of a header.

``` {language="lua"}
local function isbreak(ln) -- requires *L, not *l
    return find(ln, "\n", #ln, true) and not match(ln, "[%w%-_]+%s*:")
end
```

For MIME entities the next line should begin with the boundary text.

``` {language="lua"}
local function isboundary(marker, ln)
    local p, pe = find(ln, marker, 1, true)

    if p == 1 then
        if find(ln, "^\r?\n?$", pe + 1) then
            return "begin"
        elseif find(ln, "^--\r?\n?$", pe + 1) then
            return "end"
        end
    end

    return false
end
```

#### <span>`socket:write(...)` </span>

Same as Lua <span>`file:write` </span>.

#### <span>`socket:flush([mode][, timeout])` </span>

Flushes output buffer. Mode is one of the “nlf” flags described in
<span>`socket.connect` </span>. A nil mode implies “n”, i.e. no
buffering and effecting a full flush. An empty string mode resolves to
the configured output buffering mode.

#### <span>`socket:fill(size[, timeout])` </span>

Fills the input buffer with ‘size’ bytes. Returns true on success, false
and an error code on failure.

#### <span>`socket:unget(string)` </span>

Writes ‘string’ to the head of the socket input buffer.

#### <span>`socket:pending()` </span>

Returns two numbers—the counts of buffered bytes in the input and output
streams. This does not include the bytes in the kernel’s buffer.

#### <span>`socket:uncork()` </span>

Disables TCP\_NOPUSH, TCP\_CORK, or equivalent socket option.

#### <span>`socket:recv(format [, mode])` </span>

Similar to <span>`socket:read` </span>, except takes only a single
format and returns immediately without polling. On success returns the
string or number. On failure returns nil and a numeric error
code–usually EAGAIN or EPIPE. Does not use error handler.

‘mode’ is as described in <span>`socket.connect` </span>, and defaults
to the configured input mode.

#### <span>`socket:send(string, i, j [, mode])` </span>

Write out the slice ‘string’[i,j]. Similar to passing
<span>`string:sub(i, j)` </span>, but without instantiating a new string
object. Immediately returns two values: count of bytes written (0 to
j-i+1), and numerical error code, if any (usually EAGAIN or EPIPE).

#### <span>`socket:recvfd([prepbufsiz][, timeout])` </span>

Receive an ancillary socket message with accompanying descriptor.
‘prepbufsiz’ specifies the maximum message size to expect.

This routine bypasses I/O buffering.

Returns message-string, socket-object on success; nil, nil,
error-integer on failure. On success socket-object may still be nil.
Message truncation is treated as an error condition.

#### <span>`socket:sendfd(msg, socket[, timeout])` </span>

Send an ancillary socket message with accompanying descriptor. ‘msg’
should be a non-zero-length string, which some platforms require.
‘socket’ should be a Lua file handle, <span>`cqueues` </span>socket,
integer descriptor, or nil.

This routine bypasses I/O buffering.

Returns true on success; false and an error code on failure.

#### <span>`socket:shutdown(how)` </span>

Simple binding to <span>`shutdown(2)` </span>. ‘how’ is a string
containing one or both of the flags “r” or “w”.

   flag  description
  ------ ------------------------------------------------
    r    analagous to <span>`shutdown(SHUT_RD)` </span>
    w    analagous to <span>`shutdown(SHUT_WR)` </span>

#### <span>`socket:eof([which])` </span>

Returns boolean values representing whether EOF has been received on the
input channel, and whether the output channel has signaled closure (e.g.
<span>`EPIPE` </span>). $which$ is a string containing one or more of
the characters “r” and “w”, which return the state of the input or
output channel, respectively, in the order specified. $which$ defaults
to “rw”.

Note that <span>`socket:shutdown` </span> does not change the state of
these values. They are set only upon receiving the condition after I/O
is attempted.

#### <span>`socket:peername()` </span>

Returns one, two, or three values. On success, returns three values for
AF\_INET and AF\_INET6 sockets—the address family number, IP address
string, and IP port. For AF\_UNIX sockets, returns the address family
and file path. If the socket is not yet connected, returns the address
family AF\_UNSPEC, usually numeric 0.

On failure returns nil and a numeric error code.

#### <span>`socket:peereid()` </span>

Queries the effective UID and effective GID of an AF\_UNIX, SOCK\_STREAM
peer as cached by the kernel when the stream initially connected.

Returns two numbers representing the UID and GID, respectively, on
success, otherwise nil and a numeric error code.

#### <span>`socket:peerpid()` </span>

Queries the PID of a AF\_UNIX, SOCK\_STREAM peer as cached by the kernel
when the stream initially connected. This capability is unsupported on
OS X and FreeBSD; they only provide <span>`getpeereid` </span>, which
cannot provide the PID.

Returns a number representing the PID on success, otherwise nil and a
numeric error code.

#### <span>`socket:localname()` </span>

Identical to <span>`socket:peername` </span>, but returns the local
address of the socket.

#### <span>`socket:stat()` </span>

Returns a table containing two subtables, ‘sent’ and ‘rcvd’, which each
have three fields—.count for the number of bytes sent or received, a
boolean .eof signaling whether input or output has been shutdown, and
.time logging the last send or receive operation.

#### <span>`socket:close()` </span>

Explicitly and immediately close all internal descriptors. This routine
ensures all descriptors are properly cancelled.

<span>cqueues.errno</span>

#### <span>`errno[]` </span>

A table mapping all system error string macros to numerical error codes,
and all numerical error codes to system error string macros. Thus,
`errno.EAGAIN` evaluates to a numeric error code, and
`errno[errno.EAGAIN]` evaluates to the string “EAGAIN”.

#### <span>`errno.strerror(code)` </span>

Returns string returned by strerror(3).

<span>cqueues.signal</span>

#### <span>`signal[]` </span>

A table mapping signal string macros to numerical signal codes. In all
likelihood, `signal.SIGKILL` evaluates to the number 9.

#### <span>`signal.strsignal(code)` </span>

Returns string returned by strsignal(3).

#### <span>`signal.ignore(signal [, signal \ldots  ])` </span>

Set the signal handler to SIG\_IGN for the specified signals.

#### <span>`signal.default(signal [, signal \ldots ])` </span>

Set the signal handler to SIG\_DFL for the specified signals.

#### <span>`signal.discard(signal [, signal \ldots ])` </span>

Set the signal handler to a builtin “noop” handler for the specified
signals. Use this is you want signals to interrupt syscalls.

#### <span>`signal.block(signal [, signal \ldots ])` </span>

Block the specified signals.

#### <span>`signal.unblock(signal [, signal \ldots ])` </span>

Unblock the specified signals.

#### <span>`signal.raise(signal [, signal \ldots ])` </span>

raise(3) the specified signals.

#### <span>`signal.type(obj)` </span>

Return the string “signal listener” if $obj$ is a signal listener
object, or $nil$ otherwise.

#### <span>`signal.interpose(name, function)` </span>

Add or interpose a signal listener class method. Returns the previous
method, if any.

#### <span>`signal.listen(signal [, signal \ldots ])` </span>

Returns a signal listener object for the specified signals. Semantics
differ between platforms:

##### kqueue

BSD <span>`kqueue` </span> provides the most intuitive behavior. All
listeners will detect a signal sent to the process irrespective of
whether the signal is ignored, blocked, or delivered. However,
EVFILT\_SIGNAL is edge-triggered, which means no notification of
delivery of a pending signal upon being unblocked.

##### signalfd

Linux <span>`signalfd` </span> will not detect ignored or delivered
signals, and only one signalfd object will poll ready per signal.

##### sigtimedwait

Solaris provides no signal polling kernel primitive. Instead, the
pending set is periodically queried using <span>`sigtimedwait` </span>.
See <span>`signal:settimeout` </span>. Like Linux, only one listener can
notify per interrupt.

To be portable the application must block the relevant signals. See
<span>`signal.block` </span>. Otherwise, neither Linux nor Solaris will
be able to detect the interrupt. Any signal should be assigned to one
listener only, although any listener may query multiple signals.

Alternatively, applications may start a dedicated thread to field
incoming signals, and send notifications over a socket. In the future
this may be provided as an optional listener implementation.

See also <span>`cqueue:pause` </span> for another, if crude,
alternative.

#### <span>`signal:wait([timeout])` </span>

Polls for the signal set passed to the constructor. Returns the signal
number, or nil on timeout.

#### <span>`signal:settimeout(timeout)` </span>

Set the polling interval for implementations such as Solaris which lack
a signal polling kernel primitive. On such systems signal:wait merely
queries the pending set every ‘timeout’ seconds.

<span>cqueues.thread</span>

#### <span>`thread.type(obj)` </span>

Return the string “thread” if $obj$ is a thread object, or $nil$
otherwise.

#### <span>`thread.self()` </span>

Returns the LWP thread object for the running Lua instances. Threads not
started via thread.start return nil.

#### <span>`thread.start(function [, string [, string \ldots ]])` </span>

Generates a socket pair, starts a POSIX LWP thread, initializes a new
Lua VM instance, preloads the <span>`cqueues` </span>library, and loads
and executes the specified function from the new LWP thread and Lua
instance. The function receives as the first parameter one end of the
socket pair—instantiated as a <span>`cqueues.socket` </span>
object—followed by the string parameters passed to thread.start.

The new LWP thread starts with all signals blocked.

Returns a thread object and a socket object—the other end of the socket
pair. The thread object is pollable, and readiness signals that the LWP
thread has exited, or is imminently about to exit.

On error returns two nils and an error code.

#### <span>`thread.join([timeout])` </span>

Wait for the thread to terminate. Calling the equivalent of
thread.self():join() is disallowed.

Returns a boolean and error value. If false, error value is an error
code describing a local error, usually <span>`EAGAIN` </span> or
<span>`ETIMEDOUT` </span>. If true, error value is 1) an error code
describing a system error which the thread encountered, 2) an error
message string returned by the new Lua instance, or 3) nil if completed
successfully.

<span>cqueues.notify</span>

#### <span>`notify[]` </span>

A table mapping bitwise flags to names, and vice-versa.

    name   description
  -------- ----------------------------------------------------------
   CREATE  file creation event
   ATTRIB  metadata change event
   MODIFY  modification to file contents or directory entries
   REVOKE  permission revoked
   DELETE  file deletion event
    ALL    bitwise-or of CREATE, DELETE, ATTRIB, MODIFY, and REVOKE

#### <span>`notify.flags(bitset[, bitset \ldots ])` </span>

Returns an iterator over the flags in the specified bitwise change sets.
Thus,
`notify.flags(bit32.xor(notify.CREATE, notify.DELETE), notify.MODIFY)`
returns an iterator returning all three flags.

#### <span>`notify.type(obj)` </span>

Return the string “file notifier” if $obj$ is a notification object, or
$nil$ otherwise.

#### <span>`notify.opendir(path[, changes ])` </span>

Returns a notification object associated with the specified directory.
Directory change events are limited to the set, ‘changes’, or to
notify.ALL if nil.

#### <span>`notify:add(name[, changes ])` </span>

Track the specified file name within the notification directory.
‘changes’ defaults to notify.ALL if nil.

#### <span>`notify:get([timeout])` </span>

Returns a bitwise change set and a filename on success.

#### <span>`notify:changes([timeout])` </span>

Returns an iterator over the <span>`notify:get` </span> method.

<span>cqueues.dns</span>

As the internal DNS implementation has no global state,
<span>`cqueues.dns` </span> is mostly a convenience wrapper around other
facilities.

#### <span>`dns.version()` </span>

Returns the release, ABI, and API version numbers of the internal DNS
implementation as three numbers.

#### <span>`dns.query(name[, type][, class][, timeout])` </span>

Proxies the <span>`resolvers:query` </span> method of the internal
resolver pool. If no resolver pool has been set with <span>`dns:setpool`
</span>, creates a new stub resolver pool.

#### <span>`dns.setpool(pool)` </span>

Sets the internal resolver pool for use by subsequent calls to
<span>`dns.query` </span> to $pool$.

#### <span>`dns.getpool()` </span>

Returns the internal resolver pool. This routine should never return
nil, as it will automatically create a new resolver pool if none has
been set yet.

<span>cqueues.dns.record</span>

DNS resource record objects are implemented within
<span>`cqueues.dns.record` </span>. The global tables and shared methods
are documented below. The type-specific accessory methods are quite
numerous. Until documented please confer with cqueues/src/dns.c. Also,
the accessory method names are usually equivalent to the structure
member names in cqueues/src/lib/dns.h, which in return usually reflect
the member names in the relevant RFC.

The <span>`__tostring` </span> metamethod returns a representation of
the record data only, excluding the name, type, ttl, etc. For an A
record, it’s equivalent to string.format(“%s”, <span>`rr:addr()`
</span>). For MX—which has multiple members—it’s string.format(“%d %s”,
rr:preference(), rr:host()).

#### <span>`record.type[]` </span>

A table mapping DNS record type string identifiers to number values, and
vice-versa. So, <span>`record.type.A` </span> evaluates to 1, the IANA
numeric record type. String identifiers are only provided for record
types which are directly parseable and composable by the library.
Currently supported types include A, NS, CNAME, SOA, PTR, MX, TXT, AAAA,
SRV, OPT, SSHFP, and SPF. Other record types can be instantiated, but
the numeric type must be used and the only methods available operate on
the raw rdata.

#### <span>`record.class[]` </span>

A table mapping DNS record class string identifiers to number values,
and vice-versa. At present the only class included is IN.

#### <span>`record.sshfp[]` </span>

A table mapping DNS SSHFP record string identifiers to the number
values—RSA, DSA, and SHA1.

#### <span>`record.type(obj)` </span>

Return the string “dns record” if $obj$ is a record object, or $nil$
otherwise.

#### <span>`record:section()` </span>

Returns the section identifier from whence the record came, if derived
from a packet. Specifically, QUESTION, ANSWER, AUTHORITY, or ADDITIONAL.
See <span>`cqueues.dns.packet.section[]` </span>.

#### <span>`record:name()` </span>

Returns the uncompressed record domain name as a string.

#### <span>`record:type()` </span>

Returns the numeric record type. If ‘rr’ holds an AAAA record, then the
return value of rr:type() will compare equal to <span>`record.type.AAAA`
</span>.

#### <span>`record:class()` </span>

Returns the numeric record class. See <span>`record.class[]` </span>.

#### <span>`record:ttl()` </span>

Returns the record TTL.

<span>cqueues.dns.packet</span>

DNS packets are stored in a simple structure encapsulating the raw
packet data. One consequence is that packets are append only. Because a
packet is composed of four adjacent sections, when building a packet all
the information necessary should be at-hand so that records can be
appended in order.

The <span>`__tostring` </span> metamethod composes a string similar to
the output of the venerable dig utility.

#### <span>`packet.section[]` </span>

A table mapping packet section string identifiers to number values, and
vice-versa. A packet is composed of only four sections: QUESTION,
ANSWER, AUTHORITY, and ADDITIONAL.

#### <span>`packet.opcode[]` </span>

A table mapping packet opcode string identifiers to number values, and
vice-versa. The currently mapped opcodes are QUERY, IQUERY, STATUS,
NOTIFY, and UPDATE.

#### <span>`packet.rcode[]` </span>

A table mapping packet rcode string identifiers to number values, and
vice-versa. The currently mapped rcodes are NOERROR, FORMERR, SERVFAIL,
NXDOMAIN, NOTIMP, REFUSED, YXDOMAIN, YXRRSET, NXRRSET, NOTAUTH, and
NOTZONE.

#### <span>`packet.type(obj)` </span>

Return the string “dns packet” if $obj$ is a packet object, or $nil$
otherwise.

#### <span>`packet.interpose` </span>

Add or interpose a packet class method. Returns the previous method, if
any.

#### <span>`packet.new([prepbufsiz])` </span>

Instantiate a new packet object. ‘prepbufsiz’ is the maximum space
available for appending compressed records. For constructing a packet
with a single question, the most space possibly necessary is 260—256
bytes for the name, and 2 bytes each for the type and class (a QUESTION
record has no TTL or rdata section).

#### <span>`packet:qid()` </span>

Returns the 16-bit QID value.

#### <span>`packet:flags()` </span>

Returns a table of packet header flags.

    field     type    description
  --------- --------- -------------------------------------------------------------
     .qr     integer  specifies whether the packet is a query (0) or response (1)
   .opcode   number   specifies the query type
     .aa     boolean  signals an authoritative answer
     .tc     boolean  signals packet truncation
     .rd     boolean  signals “recursion desired”
     .ra     boolean  signals “recursion available”
     .z      boolean  reserved by RFC 1035 and used by other RFCs
   .rcode    integer  specifies the response disposition

#### <span>`packet:count([sections])` </span>

Returns a count of records in the sections specified by the bitwise
parameter ‘sections’. Defaults to `packet.section.ALL`, which is the XOR
of all four sections.

#### <span>`packet:grep{ \ldots }` </span>

Returns a record iterator over the packet according to all the criteria
specified by the optional table parameter.

    field    description
  ---------- -----------------------------------------------------------
   .section  select records by bitwise AND with the specified sections
    .type    select records of this type (not bitwise)
    .class   selects records of this class (not bitwise)
    .name    select records with this name

<span>cqueues.dns.config</span>

The traditional BSD /etc/resolv.conf file is the prototype for this
module, although it’s also capable of parsing /etc/nsswitch.conf.
<span>`cqueues.dns.config` </span> objects are used when instantiating
new resolver objects, and provide the general options controlling a
resolver.

The <span>`__tostring` </span> metamethod composes a string adhering to
/etc/resolv.conf syntax, with /etc/nsswitch.conf alternatives as
comments.

#### <span>`config[]` </span>

A table mapping flag identifiers to number values.

       field       description
  ---------------- -----------------------------------------------------
    TCP\_ENABLE    fall back to TCP when truncation detected (default)
     TCP\_ONLY     only use TCP when querying
    TCP\_DISABLE   do not fall back to TCP
    RESOLV\_CONF   specifies BSD /etc/resolv.conf input syntax
   NSSWITCH\_CONF  specifies Solaris /etc/nsswitch.conf input syntax

#### <span>`config.type(obj)` </span>

Return the string “dns config” if $obj$ is a config object, or $nil$
otherwise.

#### <span>`config.interpose(name, function)` </span>

Add or interpose a config class method. Returns the previous method, if
any.

#### <span>`config.new{ \ldots }` </span>

Returns a new config object, optionally initialized according to the
specified table values.

<span> c | c | p<span>5in</span> </span> field & type & description\
.nameserver & table & list of IP address strings to use for stub
resolvers\
.search & table & list of domain suffixes to append to query names\
.lookup & table & order of lookup methods—“file” and “bind”\
.options & table & canonical location for .edns0, .ndots, .timeout,
.attempts, .rotate, .recurse, .smart, and .tcp options\
..edns0 & boolean & enable EDNS0 support\
..ndots & number & if query name has fewer labels than this, reverse
suffix search order\
..timeout & number & timeout between query retries\
..attempts & number & maximum number of attempts per nameserver\
..rotate & boolean & randomize nameserver selection\
..recurse & boolean & query recursively instead of as a simple stub
resolver\
..smart & boolean & for NS, MX, SRV and similar record queries, resolve
the A record if not included as glue in the initial answer\
..tcp & number & see TCP\_ENABLE, TCP\_ONLY, TCP\_DISABLE in
<span>`config[]` </span>\
.interface & string & IP address to bind to when querying (e.g.
[192.168.1.1]:1234)

#### <span>`config.stub{ \ldots }` </span>

Returns a config object initialized for a stub resolver by loading the
relevant system files; e.g. /etc/resolv.conf and /etc/nsswitch.conf.
Takes optional initialization values like <span>`config.new` </span>.

#### <span>`config.root{ \ldots }` </span>

Returns a config object initialized for a recursive resolver. Takes
optional initialization values like <span>`config.new` </span>.

#### <span>`config:loadfile(file[, syntax])` </span>

Parse the Lua file object ‘file’. ‘syntax’ describes the format, which
should be RESOLV\_CONF (default), or NSSWITCH\_CONF.

#### <span>`config:loadpath(path[, syntax])` </span>

Like :loadfile, but takes a file path.

#### <span>`config:get()` </span>

Returns the configuration as a Lua table structure. See
<span>`config.new` </span> for a description of the values.

#### <span>`config:set{ \ldots }` </span>

Apply the defined configuration values. The table should have the same
structure as described for <span>`config.new` </span>.

<span>cqueues.dns.hosts</span>

The traditional BSD /etc/hosts file is the prototype for this module,
and provides resolvers the data source for the “file” lookup method.

The <span>`__tostring` </span> metamethod composes a string adhering to
/etc/hosts syntax.

#### <span>`hosts.type(obj)` </span>

Return the string “dns hosts” if $obj$ is a hosts object, or $nil$
otherwise.

#### <span>`hosts.interpose(name, function)` </span>

Add or interpose a hosts class method. Returns the previous method, if
any.

#### <span>`hosts.new()` </span>

Returns a new hosts object.

#### <span>`hosts.stub()` </span>

Returns a host object initialized for a stub resolver by loading the
relevant system files; e.g. /etc/hosts.

#### <span>`hosts.root()` </span>

Returns a hosts object initialized for a recursive resolver.

#### <span>`hosts:loadfile(file)` </span>

Parse the Lua file object ‘file’ for host entries.

#### <span>`hosts:loadpath(path)` </span>

Like :loadfile, but takes a file path.

#### <span>`hosts:insert(address, name[, alias])` </span>

Inserts a new hosts entry. ‘address’ should be an IPv4 or IPv6 address
string, ‘name’ the domain name, and ‘alias’ a boolean—true if ‘name’ is
canonical and a valid response for a reverse address lookup.

<span>cqueues.dns.hints</span>

The internal DNS library is implemented as a recursive resolver. No
matter whether configured as a stub or recursive resolver, when a query
is submitted it consults a “hints” database for the initial name servers
to contact. In stub mode these would usually be the local recursive,
caching name servers, derived from the <span>`cqueues.dns.config`
</span> object; in recursive mode, the root IANA name servers.

The <span>`__tostring` </span> metamethod composes a multi-line string
indexing SOA zone names and addresses.

#### <span>`hints.type(obj)` </span>

Return the string “dns hints” if $obj$ is a hints object, or $nil$
otherwise.

#### <span>`hints.interpose(name, function)` </span>

Add or interpose a hints class method. Returns the previous method, if
any.

#### <span>`hints.new([resconf])` </span>

Returns a new hints object. ‘resconf’ is an optional
<span>`cqueues.dns.config` </span> object which in the future may be
used to initialize database behavior. Currently it’s unused, and *does
not* pre-load the name server list.

#### <span>`hints.stub([resconf])` </span>

Returns a hints object initialized for a stub resolver. If provided, the
initial hints are taken from the <span>`cqueues.dns.config` </span>
object, ‘resconf’. Otherwise, the hints are derived from a temporary
“stub” config object internally.

#### <span>`hints.root([resconf])` </span>

Returns a hints object initialized for a recursive resolver. The root
name servers are initialized from an internal database compiled into the
module. See <span>`hints.new` </span> for the function of the optional
‘resconf’.

#### <span>`hints:insert(zone, address|resconf[, priority])` </span>

Inserts a new hints entry. ‘zone’ is the domain name which anchors the
SOA (e.g. “.”, or “com.”), and ‘address’ the IPv4 or IPv6 of the
nameserver. Alternatively, in lieu of a string address a
<span>`cqueues.dns.config` </span> object can be specified, and the
addresses taken from the nameserver list property. ‘priority’ is used
for ordering nameservers in each zone.

IPv4 and IPv6 addresses can optionally contain a port component, e.g.
“[2001:503:ba3e::2:30]:123” or “[198.41.0.4]:53”.

<span>cqueues.dns.resolver</span>

This module implements a comprehensive DNS resolution algorithm, capable
of working in both stub and recursive modes, and automatically querying
for missing glue records.

The resolver implementation only supports one outstanding query per
resolver, with a 1:1 mapping between resolvers and sockets. This is
intended to promote both simplicity and security—it maximizes port
number and QID entropy to mitigate spoofing. An additional module,
<span>`cqueues.dns.resolvers` </span>, implements a resolver pool to
assist with bulk querying.

#### <span>`resolver.type(obj)` </span>

Return the string “dns resolver” if $obj$ is a resolver object, or $nil$
otherwise.

#### <span>`resolver.interpose(name, function)` </span>

Add or interpose a resolver class method. Returns the previous method,
if any.

#### <span>`resolver.new([resconf][,hosts][,hints])` </span>

Returns a new resolver object, configured according to the specified
config, hosts, and hints objects. ‘resconf’ can be either an object, or
a table suitable for passing to <span>`config.new` </span>. ‘hosts’ and
‘hints’, if nil, are instantiated according to the mode—recursive or
stub—of the config object.

#### <span>`resolver.stub{ \ldots }` </span>

Returns a stub resolver, optionally initialized to the defined config
parameters, which should have a structure suitable for passing to
<span>`cqueues.dns.config.new` </span>.

#### <span>`resolver.root{ \ldots }` </span>

Returns a recursive resolver, optionally initialized to the defined
config parameters, which should have a structure suitable for passing to
<span>`cqueues.dns.config.new` </span>.

#### <span>`resolver:query(name[, type][, class][, timeout])` </span>

Query for the DNS resource record with the specified type and class.
$name$ is the fully-qualified or prefix domain name string. $type$ and
$class$ corresponding to the IANA-assigned numeric or string identifier
for the type of answer desired, and default to A (0x01) and IN (0x01),
respectively. $timeout$ is the total elapsed time for resolution,
irrespective of the $.attempts$ and $.timeout$ configuration values.[^9]

Returns a <span>`cqueues.dns.packet` </span> answer packet on success,
or nil and a numeric error code on failure. The answer may not actually
have anything in the ANSWERS section; e.g. if the RCODE is NXDOMAIN.

This routine is a simple wrapper around <span>`resolver:submit` </span>
and <span>`resolver:fetch` </span>.

#### <span>`resolver:submit(name[, type][, class])` </span>

Resets the query state and submits a new query. Returns true on success,
or false and an error number on failure. This routine does not poll.

#### <span>`resolver:fetch()` </span>

Process a previously submitted query. Returns a <span>`dns.packet`
</span> object on success, or nil and an error number on failure—usually
`EAGAIN`. This routine does not poll.

#### <span>`resolver:stat()` </span>

Returns a table of statistics for the resolver instance.

<span> c | p<span>5in</span></span> field & description\
.queries & number of queries submitted\
.udp.sent.count & number of UDP packets sent\
.udp.sent.bytes & number of UDP bytes sent\
.udp.rcvd.count & number of UDP packets received\
.udp.rcvd.bytes & number of UDP bytes received\
.tcp.sent.count & number of TCP packets sent\
.tcp.sent.bytes & number of TCP bytes sent\
.tcp.rcvd.count & number of TCP packets received\
.tcp.rcvd.bytes & number of TCP bytes received\

#### <span>`resolver:close()` </span>

Explicitly destroy the resolver object, immediately closing all internal
descriptors. This routine ensures all descriptors are properly
cancelled.

<span>cqueues.dns.resolvers</span>

A resolver pool is both a factory and container for resolver objects.
When a resolver is requested it attempts to pull one from the internal
queue. If none is available and the $.hiwat$ mark has not been reached,
a new resolver is created, otherwise the calling coroutine waits on a
conditional variable until a resolver becomes available, or the request
times-out. When a resolver is placed back into the queue it is cached if
the number of cached resolvers is below $.lowat$, otherwise it is closed
and discarded.

#### <span>`resolvers.type(obj)` </span>

Return the string “dns resolver pool” if $obj$ is a resolver pool
object, or $nil$ otherwise.

#### <span>`resolvers.new([resconf][,hosts][,hints])` </span>

Behaves similar to <span>`resolver:new` </span>. Returns a new resolver
pool object.

#### <span>`resolvers.stub{ \ldots }` </span>

Returns a stub resolver pool, with each resolver optionally initialized
to the defined config parameters, which should have a structure suitable
for passing to <span>`cqueues.dns.config.new` </span>.

#### <span>`resolvers.root{ \ldots }` </span>

Returns a recursive resolver pool, with each resolver optionally
initialized to the defined config parameters, which should have a
structure suitable for passing to <span>`cqueues.dns.config.new`
</span>.

#### <span>`resolvers:query(name[, type][, class][, timeout])` </span>

Behaves similar to <span>`resolver:query` </span>, except that $timeout$
is inclusive of the time spent waiting for a resolver to become
available in the pool.

#### <span>`resolvers:get([timeout])` </span>

Return a resolver from the pool. If $timeout$ is expires, returns nil
and ETIMEDOUT.

#### <span>`resolvers:put(resolver)` </span>

Returns $resolver$ back to the pool. Any waiting coroutines are woken.

<span>cqueues.condition</span>

This module implements a condition variable. A condition variable can be
used to queue multiple Lua threads to await a user-defined event. Unlike
some condition variable implementations, this one does not implement the
monitor pattern directly. A monitor uses both a mutex and a condition
variable. However, a full monitor will usually be unnecessary as
coroutines do not run in parallel. Monitors are more a necessity in
pre-emptive threading environments.

The condition variable primitive can be used to implement mutexes,
semaphores, and monitors.

#### <span>`condition.type(obj)` </span>

Returns the string “condition” if $obj$ is a condition variable, or
$nil$ otherwise.

#### <span>`condition.interpose(name, function)` </span>

Add or interpose a condition class method. Returns the previous method,
if any.

#### <span>`condition.new([lifo])` </span>

Returns a new condition variable object. If ‘lifo’ is `true`, waiting
threads are woken in LIFO order, otherwise in FIFO order.

Note that the <span>`cqueues` </span>scheduler might schedule execution
of multiple woken threads in a different order. The LIFO/FIFO behavior
is most useful when implementing a mutex and for whatever reason you
wish to select the thread which has waited either the longest or
shortest amount of time.

#### <span>`condition:wait([\ldots])` </span>

Wait on the condition variable. Additional arguments are yielded to the
<span>`cqueues` </span>controller for polling. Passing an integer, for
example, allows you to effect a timeout. Passing a socket allows you to
wait on both the condition variable and the socket.

Returns true if the thread was woken by the condition variable, and
false otherwise. Additional values are returned if they polled as ready.
It’s possible that both the condition variable and, e.g., a socket
object poll ready simultaneously, in which case two values are
returned—true and the socket object.

You can also directly yield a condition variable, along with other
condition variables, timeouts, or pollable objects, to the
<span>`cqueues` </span>controller with <span>`cqueues.poll` </span>.

#### <span>`condition:signal([n])` </span>

Signal a condition, wakening one or more waiting threads. If specified,
a maximum of ‘n’ threads are woken, otherwise all threads are woken.

<span>cqueues.promise</span>

This module implements the promise/future pattern. It most closely
resembles the C++11 std::promise and std::future APIs rather than the
JavaScript Promise API. JavaScript lacks coroutines, so JavaScript
Promises are overloaded with complex functionality intended to mitigate
the problems with lacking such a primitive. The typical usage of
promises/futures with C++11’s threading model mirrors how they would be
typically used in <span>`cqueues` </span>’ thread–like model.

The promise object uses a condition variable to wakeup any coroutines
waiting inside <span>`promise:wait` </span> or <span>`promise:get`
</span>.

#### <span>`promise.type(obj)` </span>

Returns the string “promise” if $obj$ is a promise, or $nil$ otherwise.

#### <span>`promise.new([f[, \ldots]])` </span>

Returns a new promise object. $f$ is an optional function to run
asynchronously, to which any subsequent arguments are passed. $f$ is
called using <span>`pcall` </span>, and the return values of
<span>`pcall` </span> are passed directly to <span>`promise:set`
</span>.

#### <span>`promise:status()` </span>

Returns “pending” if the promise is yet unresolved, “fulfilled” if the
promise has been resolved (<span>`promise:get` </span> will return the
values), or “rejected” if the promise failed (<span>`promise:get`
</span> will throw an error).

#### <span>`promise:set(ok[, \ldots])` </span>

Resolves the state of the promise object. If $ok$ is <span>`true`
</span>then any subsequent arguments will be returned to
<span>`promise:get` </span> callers. If $ok$ is <span>`false`
</span>then an error will be thrown to <span>`promise:get` </span>
callers, with the error value taken from the first subsequent argument,
if any.

<span>`promise:set` </span> can only be called once. Subsequent
invocations will throw an error.

#### <span>`promise:get([timeout])` </span>

Wait for resolution of the promise object (if unresolved) and either
return the resolved values directly or, if the promise was “rejected”,
throw an error. If $timeout$ is specified, returns nothing if the
promise is not resolved within the timeout.

#### <span>`promise:wait([timeout])` </span>

Wait for resolution of the promise object or until $timeout$ expires.
Returns promise object if the status is no longer pending (i.e.
“fulfilled” or “rejected”), otherwise <span>`nil` </span>.

#### <span>`promise:pollfd()` </span>

Returns a condition variable suitable for polling which is used to
signal resolution of the promise to any waiting threads.[^10]

<span>cqueues.auxlib</span>

The auxiliary module exposes some convenience interfaces, including some
interfaces to help with application integration or for dealing with
quirky behavior that hasn’t yet been changed because of API stability
concerns.

#### <span>`auxlib.assert(v [\ldots])` </span>

Similar to Lua’s built-in <span>`assert` </span>, except that when $v$
is false searches the argument list for the first non-nil, non-false
value to use as the message. If the message is an integer, applies
<span>`errno.strerror` </span> to derive a human readable string.

This routine can be explicitly monkey patched to be the global
<span>`assert` </span>.

Most <span>`cqueues` </span>interfaces return a single integer error
rather than the Lua-idiomatic string followed by an integer error. The
original concern was that most “errors” would be EAGAIN, ETIMEDOUT, or
EPIPE, which occur very often and would be costly to continually copy
onto the stack as strings, especially given that they’d normally be
discarded. In the future the plan is to revert to the idiomatic return
protocol used by Lua’s <span>`file` </span> API, but memoize the more
common errno string representations using upvalues so they can be
efficiently returned.

#### <span>`auxlib.fileresult(v [\ldots])` </span>

Serves a similar purpose as <span>`auxlib.assert` </span>, except on
error returns $v$ (<span>`nil` </span>or <span>`false` </span>) followed
by the string message and any integer error. For example, in

``` {language="lua"}
    local v, why, syserr = fileresult(false, nil, EPERM)
```

$v$ is <span>`false` </span>, $why$ is “Operation not permitted”, and
$syserr$ is EPERM. Whereas with

``` {language="lua"}
    local v, why, syserr = fileresult(nil, ``No such file or directory'')
```

$v$ is <span>`nil` </span>, $why$ is “No such file or directory”, and
$syserr$ is <span>`nil` </span>.

#### <span>`auxlib.resume(co [\ldots])` </span>

Similar to Lua’s built-in <span>`coroutine.resume` </span>, except that
when coroutines yield using <span>`cqueues.poll` </span> recursively
yields up the stack until the controller is reached, and then silently
restart the coroutine when the poll operation completes. This permits
creating iterators which can transparently yield. The application must
be careful to ensure that this wrapper is used at every point in a
yield/resume chain to get the automatic behavior.

This routine can be explicitly monkey patched to be
<span>`coroutine.resume` </span>.

#### <span>`auxlib.tostring(v)` </span>

Similar to Lua’s built-in <span>`tostring` </span>, except supports
yielding of \_\_tostring metamethods.

This routine can be explicitly monkey patched to be the global
<span>`tostring` </span>.

#### <span>`auxlib.wrap(f)` </span>

Similar to Lua’s built-in <span>`coroutine.wrap` </span>, except uses
<span>`auxlib.resume` </span> when resuming coroutines.

This routine can be explicitly monkey patched to be
<span>`coroutine.wrap` </span>.

Note that unlike <span>`cqueues:wrap` </span>, the created coroutine is
not attached to a controller.

Examples
========

HTTP SSL Request
----------------

``` {language="lua"}
local cqueues = require"cqueues"
local socket = require"cqueues.socket"

local http = socket.connect("google.com", 443)

local cq = cqueues.new()

cq:wrap(function()
    http:starttls()

    http:write("GET / HTTP/1.0\n")
    http:write("Host: google.com:443\n\n")

    local status = http:read()
    print("!", status)

    for ln in http:lines"*h" do
        print("|", ln)
    end

    local empty = http:read"*L"
    print"~"

    for ln in http:lines"*L" do
        io.stdout:write(ln)
    end

    http:close()
end)

assert(cq:loop())
```

Multiplexing Echo Server
------------------------

``` {language="lua"}
local cqueues = require"cqueues"
local socket = require"cqueues.socket"
local bind, port, wait = ...

local srv = socket.listen(bind or "127.0.0.1", tonumber(port or 8000))

local cq = cqueues.new()

cq:wrap(function()
    for con in srv:clients(wait) do
        cq:wrap(function()
            for ln in con:lines("*L") do
                cq:write(ln)
            end

            cq:shutdown("w")
        end)
    end
end)

assert(cq:loop())
```

Thread Messaging
----------------

``` {language="lua"}
local cqueues = require"cqueues"
local thread = require"cqueues.thread"

-- we start a thread and pass two parameters--`0' and '9'
local thr, con = thread.start(function(con, i, j)
    -- the `cqueues' upvalue defined above is gone
    local cqueues = require"cqueues"
    local cq = cqueues.new()

    cq:wrap(function()
        for n = tonumber(i), tonumber(j) do
            io.stdout:write("sent ", n, "\n")
            con:write(n, "\n")
             -- sleep so our stdout writes don't mix
            cqueues.sleep(0.1)
        end
    end)

    assert(cq:loop())
end, 0, 9)


local cq = cqueues.new()

cq:wrap(function()
    for ln in con:lines() do
        io.stdout:write(ln, " rcvd", "\n")
    end

    local ok, why = thr:join()

    if ok then
        print(why or "OK")
    else
        error(require"cqueues.errno".strerror(why))
    end
end)

assert(cq:loop())
```

[^1]: I have been toying with the idea of using an fd\_set in-place of a
    pollable descriptor on Windows, and taking the union of all fd\_sets
    when polling.

[^2]: Building without threading enabled is not well tested.

[^3]: This wrapper can also detect if the current coroutine was resumed
    by a controller, and if not chain yield calls—with the cooperation
    of a <span>`cqueues.resume` </span>—until a controller is reached.

[^4]: <span>`:pollfd` </span> returns the internal <span>`kqueue`
    </span>, <span>`epoll` </span>, or Ports descriptor; <span>`:events`
    </span> returns “r”; and <span>`:timeout` </span> returns the time
    to the next internal timeout event.

[^5]: The <span>`cqueues.thread` </span> module ensures threads are
    started with a filled signal mask.

[^6]: In some situations, such as with SSL/TLS, a read attempt might
    require a write, anyhow. Expanding the scope of EPIPE simplifies the
    logic required to handle various I/O failures.

[^7]: Prior to 2014-04-30, if no timeout was specified then the routine
    returned immediately.

[^8]: This is especially true of Lua’s for-loop iterator pattern.

[^9]: The `resolv.conf` $.timeout$ controls the time to wait on each
    query to a nameserver, while $.attempts$ controls how many times to
    query each nameserver in the nameserver list. Thus in the absence of
    an overall timeout, the effective timeout is $.timeout$ x
    $.attempts$ x number of nameservers.

[^10]: To improve performance of the scheduler the pollfd member is
    itself the condition variable, but it can be called as a function
    because condition variables support the \_\_call metamethod.
