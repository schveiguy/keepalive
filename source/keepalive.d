/**
 * Small utility library to ensure a reference is emplaed on the stack.
 *
 * The empty asm call is currently enough to force all current compilers to
 * give up on trying to optimize the destructor out. If this becomes incorrect
 * at some point, then a revisit is necessary.
 *
 * License: Boost-1.0. See LICENSE.MD
 *
 * Authors: Steven Schveighoffer
 *
 * Copyright: 2021 Steven Schveighoffer
 */
module keepalive;

/**
 * Create a guaranteed-stack-allocated reference. While the thing itself cannot
 * be copied, it should be usable just like the reference that it wraps.
 * Because of the destructor, it is guaranteed to be put on the stack.
 *
 * Params:
 *      val: The value to wrap. It must be a reference type.
 * Returns:
 *      A voldemort type that wraps the value. Using it should be no different
 *      than the original pointer, 
 */
@nogc nothrow @safe pure
auto keepAlive(T)(T val) if (is(T == U*, U) || is(T == class) || is(T == interface))
{
    static struct KeepAlive
    {
        T _val;
        alias _val this;
        @disable this(this);

        @nogc nothrow @safe pure ~this() {
            version (GNU) asm @nogc nothrow @safe pure { "" :: "rm" (this._val); }
            else asm @nogc nothrow @safe pure {}
        }
    }
    return KeepAlive(val);
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

    auto c2 = keepAlive(new C);
    foreach(i; 0 .. 100) GC.collect;
    assert(C.dtorcalls == 0);
}
