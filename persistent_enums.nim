##
## Persistent enums. Use symbolic names for constants with auto-generated
## int values. The enum can later be expanded by inserting new items to any
## position still preserving numeric values for old items. This is useful in
## case when you want to preserve binary (or protocol) backwards compatibility.
##
import macros, tables, sequtils, algorithm

proc crc16(data: string): uint16 =
    var x: uint8
    var crc = 0xFFFF'u16

    for i in 0 ..< data.len:
        x = uint8((crc shr 8) xor ord(data[i]))
        x = x xor (x shr 4)
        crc = (crc shl 8) xor (x shl 12) xor (x shl 5) xor x
    return crc

proc bubbleSort[T](v: var openarray[T]) =
    # Why? Because currenly nim sort doesn't work in compile time (#4065) :(
    let n = v.len
    for c in 0 ..< n - 1:
      for d in 0 ..< n - c - 1:
        if v[d] > v[d+1]:
          let t = v[d]
          v[d] = v[d+1]
          v[d+1] = t

macro persistentEnum*(b: untyped): untyped =
    result = newNimNode(nnkEnumTy).add(newEmptyNode())

    var allFields = initTable[int32, NimNode]()
    for ef in b[6]:
        var elemName: string
        var elemValue: int32
        var elem = ef

        if ef.kind == nnkAsgn:
            elem = ef[0]
            elemName = $elem
            elemValue = int32(ef[1].intVal)
        else:
            elemName = $elem
            elemValue = int32(crc16(elemName))

        doAssert(elemValue notin allFields, "Error: hash of enum value " & elemName & " collides with " & $allFields[elemValue])
        allFields[elemValue] = elem

    var allKeys = toSeq(allFields.keys())
    allKeys.bubbleSort()

    for k in allKeys:
        result.add(newNimNode(nnkEnumFieldDef).add(allFields[k], newLit(k)))

when isMainModule:
    type MyEnum = persistentEnum do:
        myValue0 = 0
        myValue1
        myValue2
        myValue3

    static:
        doAssert(myValue0.int == 0, "Persistent enum sanity check failed")
        doAssert(myValue1.int == 10916, "Persistent enum sanity check failed")
        doAssert(myValue2.int == 10951, "Persistent enum sanity check failed")
        doAssert(myValue3.int == 10982, "Persistent enum sanity check failed")

        var t = myValue3
        doAssert(t == myValue3, "Persistent enum sanity check failed")
