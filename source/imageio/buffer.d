module imageio.buffer;

import std.format : format;
import std.range.primitives;
import std.traits : isScalarType, hasElaborateDestructor,
    hasElaborateCopyConstructor, hasElaborateAssign, hasIndirections, isMutable;

enum Endianness
{
    original,
    littleToNative,
    bigToNative,
    littleToBig,
    bigToLittle
}

T adjustEndianness(T, Endianness endianness)(T from)
{
    import std.bitmanip : littleEndianToNative,
        bigEndianToNative, swapEndian;

    static if (endianness == Endianness.original)
        return from;

    else static if (endianness == Endianness.littleToNative)
        return littleEndianToNative(from);

    else static if (endianness == Endianness.bigToNative)
        return bigEndianToNative(from);

    else static if (endianness == Endianness.littleToBig ||
        endianness == Endianness.bigToLittle)
        return swapEndian(from);
}

// TODO: check previous implementation of isPOD:
// !hasElaborateDestructor!T && !hasElaborateAssign!T && !hasElaborateDestructor!T
enum isPOD(T) = __traits(isPOD, T) && !hasIndirections!T;

alias UntypedBuffer = Buffer!void;
alias ConstBuffer = Buffer!(const void);

struct Buffer(T)
{
    static assert (isPOD!T, "Only Plain Old Data (POD) types can be used!");

    T[] data;

    size_t start;
    size_t count;

    this(size_t initial_capacity)
    {
        data = new T[initial_capacity];
    }

    size_t capacity() @property
    {
        return data.length - (start + count);
    }

    void clear() @system
    {
        start = 0;
        count = 0;
    }

    void seek(size_t position)
    in { assert(position < start + count, "Position out-of-range!"); }
    body {
        count = (start + count) - position;
        start = position;
    }

    const(T[]) opSlice() inout
    {
        return this.data[start .. start + count];
    }

    ref typeof(this) skip(size_t skip_count)
    {
        this.start += skip_count;
        this.count -= skip_count;

        return this;
    }

    auto constOf() const
    {
        auto result = Buffer!(const T).init;
        result.data = this.data;
        result.start = this.start;
        result.count = this.count;
        return result;
    }

    //template untyped()
    static if (is(T : const(void)))
    {
        this(T[] data_to_wrap)
        {
            this.data = data_to_wrap;
            this.start = 0;
            this.count = data_to_wrap.length;
        }

        ref typeof(this) skipStruct(U)()
            if (is(U == struct))
        {
            skip(U.sizeof);
            return this;
        }

        U read(U, Endianness endianness = Endianness.original)() pure
        {
            U result;
            this.read!(U, endianness)(result);
            return result;
        }

        // Fills the argument with the next bytes
        void read(U, Endianness endianness = Endianness.original)(ref U to_fill)
        {
            size_t bytes_to_read;
            const(void)* start_ptr = &this.data[start];

            static if (isScalarType!U || is(U == struct) || is(U == union))
            {
                bytes_to_read = U.sizeof;
                to_fill = *cast(U*)start_ptr;
            }
            else static if (is(U == V[], V))
            {
                bytes_to_read = V.sizeof * to_fill.length;
                to_fill = (cast(V*)start_ptr)[0 .. to_fill.length];
            }

            assert(bytes_to_read <= count);
            this.skip(bytes_to_read);
        }

        const(U)[] readArray(U)(size_t count)
        {
            const(U)* start_ptr = cast(U*)&this.data[start];

            this.skip(U.sizeof * count);

            return start_ptr[0 .. count];
        }

        static if (isMutable!T)
        void writeStruct(U)(ref const U to_write)
            if (is(U == struct) && isPOD!U)
        {
            ubyte* raw = cast(ubyte*)&to_write;

            this.write(raw[0 .. U.sizeof]);
        }
    }

    alias Sink = void delegate(const T[] data);

    void consume(size_t size, scope Sink sink)
    in { assert (size <= count); }
    body {
        sink(this.data[this.start .. this.start + size]);

        this.start += size;
        this.count -= size;
    }

    static if (isMutable!T)
    void write(T[] to_write)
    {
        size_t end = start + count;
        size_t write_length = to_write.length;

        while (capacity < write_length)
            this.data.length = this.data.length? this.data.length * 2 : write_length;

        assert (this.capacity >= write_length, format("%s < %s", this.capacity, write_length));

        data[end .. end + write_length] = to_write[];

        count += write_length;
    }

    static if (isMutable!T)
    void write(T[] to_write...)
    {
        this.write(to_write);
    }

}

const(void[]) skipStruct(T)(const(void)[] bytes)
{
    return bytes[T.sizeof .. $];
}

T readStruct(T)(const void[] raw)
{
    return *cast(T*)raw.ptr;
}

unittest
{
    auto buf = Buffer!int(6);
    assert (buf.data.length == 6);
    assert (buf.start == 0);
    assert (buf.count == 0);

    buf.write(4, 2, 15, 16, 1);
    assert (buf.start == 0);
    assert (buf.count == 5);

    assert (buf.data == [4, 2, 15, 16, 1, 0]);
    assert (buf[] == [4, 2, 15, 16, 1]);

    buf.consume(3, arr => assert (arr == [4, 2, 15]));
    assert (buf.start == 3);
    assert (buf.count == 2);
    assert (buf.data == [4, 2, 15, 16, 1, 0]); // no change
    assert (buf[] == [16, 1]);

}

unittest
{
    static struct Coord
    {
        int x, y;
    }

    auto b = UntypedBuffer(20);

    auto coord = Coord(3, 4);
    b.writeStruct(coord);
    ubyte[] bytes = cast(ubyte[])b[];

    version (LittleEndian)
    {
        assert (bytes == [3, 0, 0, 0, 4, 0, 0, 0]); //, format("%s", cast(ubyte[])bytes));
    }
    else version (BigEndian)
    {
        assert (bytes == [0, 0, 0, 3, 0, 0, 0, 4]);
    }
}
