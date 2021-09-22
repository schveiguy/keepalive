/**
 * Small utility library to ensure a reference is emplaed on the stack. If used
 * without the KeepAliveOpaqueCall version, then the performance impact should
 * be none. However, it has not been proven that merely having a dstructor is
 * enough to keep the optimizer from removing the dead store. Therefore, the
 * version exists in case that proves to be the case.
 *
 * License: Boost-1.0. See LICENSE.MD
 *
 * Authors: Steven Schveighoffer
 *
 * Copyright: 2021 Steven Schveighoffer
 */
module keepalive;

@nogc nothrow pure @safe {

version(KeepAliveOpaqueCall)
{
    private void _opaque() {}
    pragma(mangle, _opaque.mangleof) extern(C) void opaque();
}

/**
 * Create a guaranteed-stack-allocated reference. While the thing itself cannot
 * be copied, it should be usable just like the reference that it wraps.
 * Because of the destructor, it is guaranteed to be put on the stack.
 *
 * If the KeepAliveOpaqueCall version is set, then a call to an opaque function which
 * does nothing is inserted into the destructor. This is a stopgap measure in
 * case a compiler has figured out it can eliminate the dead store. While this
 * might be less performant, it is better than using GC.addRoot and
 * GC.removeRoot.
 *
 * Params:
 *      val: The value to wrap. It must be a reference type.
 * Returns:
 *      A voldemort type that wraps the value. Using it should be no different
 *      than the original pointer, 
 */
auto keepalive(T)(T val) if (is(T == U*, U) || is(T == class) || is(T == interface))
{
    static struct KeepAlive
    {
        T _val;
        alias _val this;
        @disable this(this);

        @nogc nothrow @safe pure ~this() {
            version(KeepAliveOpaqueCall)
                opaque();
        }
    }
    return KeepAlive(val);
}
}

/// Note, it's not considered a hard failure for the first test to fail, as
/// it's within the compiler's right to place any pointer it wants onto the
/// stack. In the case that does happen, print a warning.
unittest
{
    static class C {
        static int dtorcalls = 0;
        ~this() { ++dtorcalls; }
    }

    import core.memory;

    auto c = new C;
    foreach(i; 0 .. 100) GC.collect;
    if(C.dtorcalls != 1)
    {
        import std.stdio;
        writeln("WARNING: keepalive issue not detected");
    }
    C.dtorcalls = 0;

    auto c2 = keepalive(new C);
    foreach(i; 0 .. 100) GC.collect;
    assert(C.dtorcalls == 0);
}
