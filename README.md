# Keepalive functionality

This is a small function to require pointers are stored on the stack. It
guarantees that the pointer should be stored on the stack for at least the
current scope.

This library implementation has 2 versions, the normal version which just adds
a destructor to a struct, and one which calls an opaque function. The opaque
function so far has not proven necessary, but is there in case a sufficiently
intelligent optimizer is found that will circumvent the dead store.

Usage is pretty simple:

```d
auto c = keepalive(new C); // c will be stored on the stack
functionTakingC(c); // auto-converts to a C
```

## When to use

This is intended as a way to ensure stack storage for a pointer. This ensures
that the GC can find the pointer. In most cases, if you are using this pointer
later, it will be availble to the GC without this mechanism. The only time you
would need to use this is if you are NOT using it later, AND it's only stored
elsewhere in a location that the GC cannot find. In this case, its lifetime is
only guaranteed to the end of the scope in which you called the `keepalive`
function.

In most cases, using a deterministic registration and deregistration of a
pointer is preferred, instead of letting the GC clean this up.

## References:

* [C# KeepAlive function](https://docs.microsoft.com/en-us/dotnet/api/system.gc.keepalive)
* [Go KeepAlive function](https://pkg.go.dev/runtime#KeepAlive)
* [Dlang specification on C Interfacing](https://dlang.org/spec/interfaceToC.html#storage_allocation)
